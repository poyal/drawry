package com.poyal.drawry

import android.app.Application
import android.net.Uri
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.poyal.drawry.core.*
import com.poyal.drawry.data.*
import java.io.File
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*

data class AppState(
    val ready: Boolean = false,
    val diaries: List<Diary> = emptyList(),
    val preferences: Preferences = Preferences(),
    val draft: Diary? = null,
    val editor: Diary? = null,
    val busy: Boolean = false,
    val canCancel: Boolean = false,
    val error: String? = null,
    val locked: Boolean = true,
    val restore: Pair<Snapshot, File>? = null,
    val erased: Boolean = false,
)

class AppModel(application: Application) : AndroidViewModel(application) {
    private val mutable = MutableStateFlow(AppState())
    val state = mutable.asStateFlow()
    lateinit var vault: Vault
        private set

    lateinit var media: MediaStore
        private set

    private var autosave: Job? = null
    private var operation: Job? = null

    init {
        action {
            vault = withContext(Dispatchers.IO) { Vault(application) }
            media = MediaStore(application, vault)
            vault.initialize()
            refresh()
            mutable.update { it.copy(ready = true, locked = it.preferences.lockEnabled) }
        }
    }

    fun error(message: String?) {
        mutable.update { it.copy(error = message) }
    }

    fun action(cancellable: Boolean = false, block: suspend () -> Unit) {
        if (mutable.value.busy) return
        operation =
            viewModelScope.launch {
                mutable.update { it.copy(busy = true, canCancel = cancellable) }
                try {
                    block()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    error(e.message ?: "작업을 완료하지 못했습니다. 다시 시도해 주세요.")
                } finally {
                    mutable.update { it.copy(busy = false, canCancel = false) }
                }
            }
    }

    fun cancelOperation() {
        if (mutable.value.canCancel) operation?.cancel()
    }

    suspend fun refresh() {
        val diaries = vault.diaries()
        val preferences = vault.preferences()
        val draft = vault.draft()
        mutable.update { it.copy(diaries = diaries, preferences = preferences, draft = draft) }
    }

    fun preferences(value: Preferences) = action {
        vault.preferences(value)
        mutable.update { it.copy(preferences = value) }
    }

    fun startEditor(diary: Diary? = null) {
        mutable.update { it.copy(editor = diary ?: it.draft ?: Diary()) }
    }

    fun updateEditor(value: Diary) {
        mutable.update { it.copy(editor = value) }
        autosave?.cancel()
        autosave =
            viewModelScope.launch {
                delay(300)
                try {
                    vault.draft(value)
                    mutable.update { it.copy(draft = value) }
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    error("초안을 저장하지 못했습니다.")
                }
            }
    }

    fun leaveEditor(discard: Boolean) = action {
        autosave?.cancelAndJoin()
        if (discard) vault.draft(null) else mutable.value.editor?.let { vault.draft(it) }
        mutable.update { it.copy(editor = null) }
        refresh()
    }

    fun saveEditor() = action {
        autosave?.cancelAndJoin()
        vault.save(requireNotNull(mutable.value.editor))
        mutable.update { it.copy(editor = null) }
        refresh()
    }

    fun import(uris: List<Uri>, preserve: Boolean) =
        action(cancellable = true) {
            for (uri in uris) {
                val editor = mutable.value.editor ?: break
                require(editor.media.size < 10) { MEDIA_LIMIT }
                val video =
                    getApplication<Application>()
                        .contentResolver
                        .getType(uri)
                        ?.startsWith("video/") == true
                val item = media.import(uri, video, preserve)
                val updated = editor.copy(media = editor.media + item)
                try {
                    updated.validate()
                    autosave?.cancelAndJoin()
                    vault.draft(updated)
                    mutable.update { it.copy(editor = updated, draft = updated) }
                } catch (e: Exception) {
                    item.files.forEach { File(vault.mediaDirectory, it).delete() }
                    throw e
                }
            }
        }

    fun editMedia(item: Media, recipe: EditRecipe) = action {
        replaceMedia(media.edit(item, recipe))
    }

    fun frame(item: Media, millis: Long) = action { replaceMedia(media.frame(item, millis)) }

    private suspend fun replaceMedia(item: Media) {
        val editor = mutable.value.editor ?: return
        val next = editor.copy(media = editor.media.map { if (it.id == item.id) item else it })
        autosave?.cancelAndJoin()
        vault.draft(next)
        mutable.update { it.copy(editor = next, draft = next) }
    }

    fun trash(diary: Diary, restore: Boolean = false) = action {
        vault.trash(diary, restore)
        refresh()
    }

    fun purge(diary: Diary) = action {
        vault.purge(diary.id)
        refresh()
    }

    fun inspect(uri: Uri, password: String, recovery: String) =
        action(cancellable = true) {
            val source = File(vault.cache, "import.drawry")
            try {
                withContext(Dispatchers.IO) {
                    getApplication<Application>().contentResolver.openInputStream(uri)!!.use { input
                        ->
                        source.outputStream().use { input.copyTo(it) }
                    }
                }
                val key =
                    if (recovery.isBlank()) null
                    else java.util.Base64.getDecoder().decode(recovery.trim())
                val result = vault.inspect(source, password.ifEmpty { null }, key)
                mutable.update { it.copy(restore = result) }
            } finally {
                source.delete()
            }
        }

    fun restore(replace: Boolean) = action {
        val pending = mutable.value.restore ?: return@action
        vault.restore(pending.first, pending.second, replace)
        mutable.update { it.copy(restore = null) }
        refresh()
    }

    fun cancelRestore() {
        mutable.value.restore?.second?.deleteRecursively()
        mutable.update { it.copy(restore = null) }
    }

    fun unlock() {
        mutable.update { it.copy(locked = false) }
    }

    fun lock() {
        if (mutable.value.preferences.lockEnabled) mutable.update { it.copy(locked = true) }
    }

    fun background() {
        if (::media.isInitialized) media.suspendViewing()
        viewModelScope.launch {
            mutable.value.editor?.let { runCatching { vault.draft(it) } }
            if (::media.isInitialized) withContext(Dispatchers.IO) { media.clearViewing() }
        }
    }

    fun foreground() {
        if (::media.isInitialized) media.allowViewing()
        if (::vault.isInitialized && mutable.value.ready && !mutable.value.busy)
            action {
                withContext(Dispatchers.IO) { vault.cleanExpiredExports() }
                vault.purgeExpired()
                refresh()
            }
    }

    fun erase() = action {
        withContext(Dispatchers.IO) { vault.erase() }
        mutable.value = AppState(erased = true, ready = true, locked = false)
    }
}
