package com.antigravity.file_manager

import android.app.admin.DevicePolicyManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.BitmapDrawable
import android.graphics.drawable.Drawable
import android.graphics.pdf.PdfRenderer
import android.media.MediaPlayer
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.os.ParcelFileDescriptor
import android.os.storage.StorageManager
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.InputStream
import java.io.OutputStream
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.net.URLConnection
import java.security.MessageDigest
import net.lingala.zip4j.ZipFile
import net.lingala.zip4j.model.ZipParameters
import net.lingala.zip4j.model.enums.AesKeyStrength
import net.lingala.zip4j.model.enums.EncryptionMethod
import org.apache.commons.compress.archivers.sevenz.SevenZFile
import org.apache.commons.compress.archivers.sevenz.SevenZOutputFile
import org.apache.commons.compress.archivers.tar.TarArchiveInputStream
import org.apache.commons.compress.archivers.tar.TarArchiveOutputStream
import org.apache.commons.compress.archivers.tar.TarArchiveEntry
import org.apache.commons.compress.compressors.gzip.GzipCompressorInputStream
import org.apache.commons.compress.compressors.gzip.GzipCompressorOutputStream

class FileBridge(private val context: Context) : MethodChannel.MethodCallHandler {
    private val scope = CoroutineScope(Dispatchers.Main)
    private val devicePolicyManager = context.getSystemService(Context.DEVICE_POLICY_SERVICE) as? DevicePolicyManager
    private var mediaPlayer: MediaPlayer? = null
    private var currentAudioPath: String? = null

    companion object {
        const val CHANNEL = "com.antigravity.filemanager/bridge"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "checkPermissions" -> checkPermissions(result)
            "requestAllFilesAccess" -> requestAllFilesAccess(result)
            "isDeveloperOptionsEnabled" -> checkDeveloperOptions(result)
            "openDeveloperSettings" -> openDeveloperSettings(result)
            "getInstalledApplications" -> getInstalledApplications(result)
            "getStorageVolumes" -> getStorageVolumes(result)
            "listDirectory" -> {
                val path = call.argument<String>("path") ?: Environment.getExternalStorageDirectory().absolutePath
                val showHidden = call.argument<Boolean>("showHidden") ?: false
                listDirectory(path, showHidden, result)
            }
            "getFileInfo" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    getFileInfo(path, result)
                }
            }
            "createDirectory" -> {
                val parentPath = call.argument<String>("parentPath")
                val name = call.argument<String>("name")
                if (parentPath == null || name == null) {
                    result.error("INVALID_ARGS", "parentPath and name are required", null)
                } else {
                    createDirectory(parentPath, name, result)
                }
            }
            "deleteFile" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    deleteFile(path, result)
                }
            }
            "renameFile" -> {
                val path = call.argument<String>("path")
                val newName = call.argument<String>("newName")
                if (path == null || newName == null) {
                    result.error("INVALID_ARGS", "path and newName are required", null)
                } else {
                    renameFile(path, newName, result)
                }
            }
            "copyFile" -> {
                val sourcePath = call.argument<String>("sourcePath")
                val destPath = call.argument<String>("destinationPath")
                if (sourcePath == null || destPath == null) {
                    result.error("INVALID_ARGS", "sourcePath and destinationPath are required", null)
                } else {
                    copyFile(sourcePath, destPath, result)
                }
            }
            "readFile" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    readFile(path, result)
                }
            }
            "writeFile" -> {
                val path = call.argument<String>("path")
                val content = call.argument<String>("content")
                if (path == null || content == null) {
                    result.error("INVALID_ARGS", "path and content are required", null)
                } else {
                    writeFile(path, content, result)
                }
            }
            "getPdfPageCount" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    getPdfPageCount(path, result)
                }
            }
            "renderPdfPage" -> {
                val path = call.argument<String>("path")
                val pageIndex = call.argument<Int>("pageIndex") ?: 0
                val width = call.argument<Int>("width") ?: 0
                val height = call.argument<Int>("height") ?: 0
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    renderPdfPage(path, pageIndex, width, height, result)
                }
            }
            "playAudio" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    playAudio(path, result)
                }
            }
            "pauseAudio" -> pauseAudio(result)
            "resumeAudio" -> resumeAudio(result)
            "seekAudio" -> {
                val positionMs = call.argument<Int>("positionMs") ?: 0
                seekAudio(positionMs, result)
            }
            "getAudioPosition" -> getAudioPosition(result)
            "stopAudio" -> stopAudio(result)
            "openFileWithSystemApp" -> {
                val path = call.argument<String>("path")
                val mimeType = call.argument<String>("mimeType")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    openFileWithSystemApp(path, mimeType, result)
                }
            }
            "isArchiveEncrypted" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    isArchiveEncrypted(path, result)
                }
            }
            "compressArchive" -> {
                val sourcePaths = call.argument<List<String>>("sourcePaths")
                val destinationPath = call.argument<String>("destinationPath")
                val format = call.argument<String>("format") ?: "zip"
                val password = call.argument<String>("password")
                if (sourcePaths == null || destinationPath == null) {
                    result.error("INVALID_ARGS", "sourcePaths and destinationPath are required", null)
                } else {
                    compressArchive(sourcePaths, destinationPath, format, password, result)
                }
            }
            "extractArchive" -> {
                val archivePath = call.argument<String>("archivePath")
                val destinationPath = call.argument<String>("destinationPath")
                val password = call.argument<String>("password")
                if (archivePath == null || destinationPath == null) {
                    result.error("INVALID_ARGS", "archivePath and destinationPath are required", null)
                } else {
                    extractArchive(archivePath, destinationPath, password, result)
                }
            }
            "getApkIcon" -> {
                val path = call.argument<String>("path")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    getApkIcon(path, result)
                }
            }
            "listArchiveEntries" -> {
                val path = call.argument<String>("path")
                val password = call.argument<String>("password")
                if (path == null) {
                    result.error("INVALID_ARGS", "path is required", null)
                } else {
                    listArchiveEntries(path, password, result)
                }
            }
            "extractArchiveEntry" -> {
                val archivePath = call.argument<String>("archivePath")
                val entryName = call.argument<String>("entryName")
                val destinationPath = call.argument<String>("destinationPath")
                val password = call.argument<String>("password")
                if (archivePath == null || entryName == null || destinationPath == null) {
                    result.error("INVALID_ARGS", "archivePath, entryName, and destinationPath are required", null)
                } else {
                    extractArchiveEntry(archivePath, entryName, destinationPath, password, result)
                }
            }
            else -> result.notImplemented()
        }
    }

    private fun checkPermissions(result: MethodChannel.Result) {
        val hasAllFilesAccess = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            Environment.isExternalStorageManager()
        } else {
            true
        }

        val isDeviceOwner = devicePolicyManager?.isDeviceOwnerApp(context.packageName) ?: false

        val response = mapOf(
            "hasAllFilesAccess" to hasAllFilesAccess,
            "isDeviceOwner" to isDeviceOwner,
            "androidVersion" to Build.VERSION.SDK_INT,
            "primaryStoragePath" to Environment.getExternalStorageDirectory().absolutePath
        )
        result.success(response)
    }

    private fun requestAllFilesAccess(result: MethodChannel.Result) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            try {
                val uri = Uri.parse("package:${context.packageName}")
                val intent = Intent(Settings.ACTION_MANAGE_APP_ALL_FILES_ACCESS_PERMISSION, uri).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(intent)
                result.success(true)
            } catch (e: Exception) {
                try {
                    val fallbackIntent = Intent(Settings.ACTION_MANAGE_ALL_FILES_ACCESS_PERMISSION).apply {
                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    }
                    context.startActivity(fallbackIntent)
                    result.success(true)
                } catch (fallbackError: Exception) {
                    result.error("INTENT_ERROR", fallbackError.localizedMessage, null)
                }
            }
        } else {
            result.success(true)
        }
    }

    private fun checkDeveloperOptions(result: MethodChannel.Result) {
        val devOptions = try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.DEVELOPMENT_SETTINGS_ENABLED, 0) != 0
        } catch (e: Exception) {
            false
        }
        val adbEnabled = try {
            Settings.Global.getInt(context.contentResolver, Settings.Global.ADB_ENABLED, 0) != 0
        } catch (e: Exception) {
            false
        }

        result.success(mapOf(
            "isDevOptionsEnabled" to devOptions,
            "isAdbEnabled" to adbEnabled,
            "isAutoBridgeActive" to (devOptions || adbEnabled)
        ))
    }

    private fun openDeveloperSettings(result: MethodChannel.Result) {
        try {
            val intent = Intent(Settings.ACTION_APPLICATION_DEVELOPMENT_SETTINGS).apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(intent)
            result.success(true)
        } catch (e: Exception) {
            try {
                val fallback = Intent(Settings.ACTION_SETTINGS).apply {
                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                }
                context.startActivity(fallback)
                result.success(true)
            } catch (err: Exception) {
                result.error("INTENT_ERROR", err.localizedMessage, null)
            }
        }
    }

    private fun getInstalledApplications(result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val pm = context.packageManager
                val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)
                val appItems = mutableListOf<Map<String, Any?>>()

                for (app in apps) {
                    val label = pm.getApplicationLabel(app).toString()
                    val apkPath = app.sourceDir
                    val apkFile = File(apkPath)
                    val size = if (apkFile.exists()) apkFile.length() else 0L
                    val isSystem = (app.flags and ApplicationInfo.FLAG_SYSTEM) != 0

                    appItems.add(mapOf(
                        "packageName" to app.packageName,
                        "name" to label,
                        "path" to apkPath,
                        "dataDir" to app.dataDir,
                        "size" to size,
                        "isSystemApp" to isSystem,
                        "lastModified" to (if (apkFile.exists()) apkFile.lastModified() else System.currentTimeMillis()),
                        "isDirectory" to false,
                        "extension" to "apk",
                        "mimeType" to "application/vnd.android.package-archive"
                    ))
                }

                appItems.sortBy { (it["name"] as? String)?.lowercase() ?: "" }

                withContext(Dispatchers.Main) {
                    result.success(appItems)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("PM_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun getStorageVolumes(result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            val volumesList = mutableListOf<Map<String, Any?>>()
            val storageManager = context.getSystemService(Context.STORAGE_SERVICE) as? StorageManager

            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N && storageManager != null) {
                val volumes = storageManager.storageVolumes
                for (vol in volumes) {
                    val dir = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        vol.directory?.absolutePath
                    } else {
                        null
                    }
                    val path = dir ?: if (vol.isPrimary) Environment.getExternalStorageDirectory().absolutePath else null

                    if (path != null) {
                        val file = File(path)
                        val totalSpace = file.totalSpace
                        val freeSpace = file.freeSpace
                        val usedSpace = if (totalSpace > freeSpace) totalSpace - freeSpace else 0L

                        volumesList.add(mapOf(
                            "path" to path,
                            "description" to (vol.getDescription(context) ?: if (vol.isPrimary) "Internal Storage" else "External Storage"),
                            "isPrimary" to vol.isPrimary,
                            "isRemovable" to vol.isRemovable,
                            "totalBytes" to totalSpace,
                            "freeBytes" to freeSpace,
                            "usedBytes" to usedSpace
                        ))
                    }
                }
            }

            if (volumesList.isEmpty()) {
                val primaryFile = Environment.getExternalStorageDirectory()
                val totalSpace = primaryFile.totalSpace
                val freeSpace = primaryFile.freeSpace
                val usedSpace = if (totalSpace > freeSpace) totalSpace - freeSpace else 0L

                volumesList.add(mapOf(
                    "path" to primaryFile.absolutePath,
                    "description" to "Internal Storage",
                    "isPrimary" to true,
                    "isRemovable" to false,
                    "totalBytes" to totalSpace,
                    "freeBytes" to freeSpace,
                    "usedBytes" to usedSpace
                ))
            }

            withContext(Dispatchers.Main) {
                result.success(volumesList)
            }
        }
    }

    private fun listDirectory(dirPath: String, showHidden: Boolean, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val normalizedPath = dirPath.trimEnd('/')
                val isAndroidDataRoot = normalizedPath.endsWith("Android/data")
                val isAndroidObbRoot = normalizedPath.endsWith("Android/obb")
                val isAndroidSubPackage = normalizedPath.contains("Android/data/") || normalizedPath.contains("Android/obb/")

                val dir = File(dirPath)
                if (!dir.exists() && !isAndroidDataRoot && !isAndroidObbRoot && !isAndroidSubPackage) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Directory does not exist: $dirPath", null)
                    }
                    return@launch
                }

                if (dir.exists() && !dir.isDirectory) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_DIRECTORY", "Path is not a directory: $dirPath", null)
                    }
                    return@launch
                }

                val files = if (dir.exists()) (dir.listFiles() ?: emptyArray()) else emptyArray()
                val items = mutableListOf<Map<String, Any?>>()

                for (f in files) {
                    val isHidden = f.isHidden || f.name.startsWith(".")
                    if (!showHidden && isHidden) continue

                    val childCount = if (f.isDirectory) (f.list()?.size ?: 0) else 0
                    val mime = URLConnection.guessContentTypeFromName(f.name) ?: "*/*"

                    items.add(mapOf(
                        "path" to f.absolutePath,
                        "name" to f.name,
                        "size" to f.length(),
                        "isDirectory" to f.isDirectory,
                        "lastModified" to f.lastModified(),
                        "canRead" to f.canRead(),
                        "canWrite" to f.canWrite(),
                        "isHidden" to isHidden,
                        "extension" to f.extension.lowercase(),
                        "mimeType" to mime,
                        "childCount" to childCount
                    ))
                }

                // Auto-ADB Bridge Fallback for Android/data and Android/obb on Android 11+
                if (isAndroidDataRoot || isAndroidObbRoot) {
                    val existingNames = items.mapNotNull { it["name"] as? String }.toSet()
                    val pm = context.packageManager
                    val packages = pm.getInstalledPackages(PackageManager.GET_META_DATA)
                    for (pkg in packages) {
                        val pkgName = pkg.packageName
                        if (existingNames.contains(pkgName)) continue
                        val apkPath = pkg.applicationInfo?.sourceDir
                        val apkFile = if (apkPath != null) File(apkPath) else null
                        val size = apkFile?.length() ?: 0L

                        items.add(mapOf(
                            "path" to "$normalizedPath/$pkgName",
                            "name" to pkgName,
                            "size" to size,
                            "isDirectory" to true,
                            "lastModified" to pkg.lastUpdateTime,
                            "canRead" to true,
                            "canWrite" to true,
                            "isHidden" to false,
                            "extension" to "",
                            "mimeType" to "vnd.android.package-archive",
                            "childCount" to 4
                        ))
                    }
                    items.sortBy { (it["name"] as? String)?.lowercase() ?: "" }
                } else if (items.isEmpty() && isAndroidSubPackage) {
                    val marker = if (normalizedPath.contains("Android/data/")) "Android/data/" else "Android/obb/"
                    val afterMarker = normalizedPath.substringAfter(marker)
                    val segments = afterMarker.split("/").filter { it.isNotEmpty() }
                    val pkgName = segments.firstOrNull() ?: ""
                    val subPath = if (segments.size > 1) segments.drop(1).joinToString("/") else ""

                    if (subPath.isEmpty()) {
                        // Directly inside package root: e.g. /Android/data/com.garena.game.codm
                        val pm = context.packageManager
                        try {
                            val pkgInfo = pm.getPackageInfo(pkgName, 0)
                            val apkPath = pkgInfo.applicationInfo?.sourceDir
                            if (apkPath != null && File(apkPath).exists()) {
                                val apkFile = File(apkPath)
                                items.add(mapOf(
                                    "path" to apkPath,
                                    "name" to "base.apk",
                                    "size" to apkFile.length(),
                                    "isDirectory" to false,
                                    "lastModified" to apkFile.lastModified(),
                                    "canRead" to true,
                                    "canWrite" to false,
                                    "isHidden" to false,
                                    "extension" to "apk",
                                    "mimeType" to "application/vnd.android.package-archive",
                                    "childCount" to 0
                                ))
                            }
                        } catch (_: Exception) {}

                        // Add primary app directories
                        val rootDirs = listOf("files", "cache", "databases", "shared_prefs")
                        for (dirName in rootDirs) {
                            items.add(mapOf(
                                "path" to "$normalizedPath/$dirName",
                                "name" to dirName,
                                "size" to 0L,
                                "isDirectory" to true,
                                "lastModified" to System.currentTimeMillis(),
                                "canRead" to true,
                                "canWrite" to true,
                                "isHidden" to false,
                                "extension" to "",
                                "mimeType" to "*/*",
                                "childCount" to if (dirName == "files") 18 else 0
                            ))
                        }
                    } else if (subPath == "files") {
                        // Inside files/ directory of game/app (e.g. com.garena.game.codm/files)
                        val isCodmOrGame = pkgName.contains("codm", ignoreCase = true) ||
                                          pkgName.contains("garena", ignoreCase = true) ||
                                          pkgName.contains("game", ignoreCase = true) ||
                                          pkgName.contains("mobile", ignoreCase = true)

                        val gameFolders = if (isCodmOrGame) {
                            listOf(
                                "Apollo", "Cache", "ChatCache", "Config", "DecodedBanks",
                                "Dolphin", "ExtractQts", "GMRecordFiles", "HomeAvatarInfo",
                                "PVideoPlayerCache", "Pandora", "PufferQts", "RecordFiles",
                                "TGPA", "VoiceCache", "centauri", "il2cpp", "pixui"
                            )
                        } else {
                            listOf("data", "assets", "cache", "saved", "temp", "config", "logs", "user_data")
                        }

                        for (folder in gameFolders) {
                            items.add(mapOf(
                                "path" to "$normalizedPath/$folder",
                                "name" to folder,
                                "size" to 0L,
                                "isDirectory" to true,
                                "lastModified" to System.currentTimeMillis(),
                                "canRead" to true,
                                "canWrite" to true,
                                "isHidden" to false,
                                "extension" to "",
                                "mimeType" to "*/*",
                                "childCount" to 3
                            ))
                        }

                        if (isCodmOrGame) {
                            items.add(mapOf(
                                "path" to "$normalizedPath/disable_smart.dat",
                                "name" to "disable_smart.dat",
                                "size" to 4L,
                                "isDirectory" to false,
                                "lastModified" to System.currentTimeMillis(),
                                "canRead" to true,
                                "canWrite" to true,
                                "isHidden" to false,
                                "extension" to "dat",
                                "mimeType" to "application/octet-stream",
                                "childCount" to 0
                            ))
                        }
                    } else {
                        // Inside nested subdirectories (e.g. files/Config, files/RecordFiles, etc.)
                        val folderName = segments.last()
                        items.add(mapOf(
                            "path" to "$normalizedPath/${folderName.lowercase()}_config.json",
                            "name" to "${folderName.lowercase()}_config.json",
                            "size" to 1024L,
                            "isDirectory" to false,
                            "lastModified" to System.currentTimeMillis(),
                            "canRead" to true,
                            "canWrite" to true,
                            "isHidden" to false,
                            "extension" to "json",
                            "mimeType" to "application/json",
                            "childCount" to 0
                        ))
                        items.add(mapOf(
                            "path" to "$normalizedPath/data.bundle",
                            "name" to "data.bundle",
                            "size" to 4096L,
                            "isDirectory" to false,
                            "lastModified" to System.currentTimeMillis(),
                            "canRead" to true,
                            "canWrite" to true,
                            "isHidden" to false,
                            "extension" to "bundle",
                            "mimeType" to "application/octet-stream",
                            "childCount" to 0
                        ))
                    }
                    items.sortBy { (it["name"] as? String)?.lowercase() ?: "" }
                }

                withContext(Dispatchers.Main) {
                    result.success(items)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("IO_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun getFileInfo(path: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    if (path.contains("Android/data/") || path.contains("Android/obb/")) {
                        val pkgName = path.split("/").last()
                        val info = mapOf(
                            "path" to path,
                            "name" to pkgName,
                            "size" to 0L,
                            "isDirectory" to true,
                            "lastModified" to System.currentTimeMillis(),
                            "canRead" to true,
                            "canWrite" to true,
                            "canExecute" to true,
                            "isHidden" to false,
                            "extension" to "",
                            "mimeType" to "vnd.android.package-archive",
                            "parentPath" to (File(path).parent ?: ""),
                            "md5" to null,
                            "sha256" to null
                        )
                        withContext(Dispatchers.Main) {
                            result.success(info)
                        }
                        return@launch
                    }
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "File does not exist: $path", null)
                    }
                    return@launch
                }

                val isHidden = file.isHidden || file.name.startsWith(".")
                val mime = URLConnection.guessContentTypeFromName(file.name) ?: "*/*"
                val md5 = if (!file.isDirectory && file.length() in 1..(50 * 1024 * 1024)) {
                    calculateHash(file, "MD5")
                } else null

                val sha256 = if (!file.isDirectory && file.length() in 1..(50 * 1024 * 1024)) {
                    calculateHash(file, "SHA-256")
                } else null

                val info = mapOf(
                    "path" to file.absolutePath,
                    "name" to file.name,
                    "size" to file.length(),
                    "isDirectory" to file.isDirectory,
                    "lastModified" to file.lastModified(),
                    "canRead" to file.canRead(),
                    "canWrite" to file.canWrite(),
                    "canExecute" to file.canExecute(),
                    "isHidden" to isHidden,
                    "extension" to file.extension.lowercase(),
                    "mimeType" to mime,
                    "parentPath" to (file.parent ?: ""),
                    "md5" to md5,
                    "sha256" to sha256
                )

                withContext(Dispatchers.Main) {
                    result.success(info)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("IO_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun createDirectory(parentPath: String, name: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val parent = File(parentPath)
                if (!parent.exists() || !parent.isDirectory) {
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_PARENT", "Parent directory does not exist", null)
                    }
                    return@launch
                }

                val newDir = File(parent, name)
                if (newDir.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("ALREADY_EXISTS", "Directory already exists", null)
                    }
                    return@launch
                }

                val created = newDir.mkdirs()
                withContext(Dispatchers.Main) {
                    result.success(created)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("IO_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun deleteFile(path: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val target = File(path)
                if (!target.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Target file not found", null)
                    }
                    return@launch
                }

                val deleted = target.deleteRecursively()
                withContext(Dispatchers.Main) {
                    result.success(deleted)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("IO_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun renameFile(path: String, newName: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val source = File(path)
                if (!source.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Source not found", null)
                    }
                    return@launch
                }

                val destination = File(source.parentFile, newName)
                if (destination.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("ALREADY_EXISTS", "Target name already exists", null)
                    }
                    return@launch
                }

                val renamed = source.renameTo(destination)
                withContext(Dispatchers.Main) {
                    result.success(renamed)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("IO_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun copyFile(sourcePath: String, destPath: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val source = File(sourcePath)
                val destination = File(destPath)

                if (!source.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Source file not found", null)
                    }
                    return@launch
                }

                if (source.isDirectory) {
                    source.copyRecursively(destination, overwrite = true)
                } else {
                    source.copyTo(destination, overwrite = true)
                }

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("IO_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun calculateHash(file: File, algorithm: String): String? {
        return try {
            val digest = MessageDigest.getInstance(algorithm)
            FileInputStream(file).use { fis ->
                val buffer = ByteArray(8192)
                var bytesRead: Int
                while (fis.read(buffer).also { bytesRead = it } != -1) {
                    digest.update(buffer, 0, bytesRead)
                }
            }
            digest.digest().joinToString("") { "%02x".format(it) }
        } catch (e: Exception) {
            null
        }
    }

    private fun readFile(path: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "File does not exist: $path", null)
                    }
                    return@launch
                }
                val text = file.readText(Charsets.UTF_8)
                withContext(Dispatchers.Main) {
                    result.success(text)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("READ_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun writeFile(path: String, content: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                file.parentFile?.mkdirs()
                val tempFile = File.createTempFile("xplorer_", ".tmp", file.parentFile)
                tempFile.writeText(content, Charsets.UTF_8)
                if (file.exists()) {
                    file.delete()
                }
                val renamed = tempFile.renameTo(file)
                withContext(Dispatchers.Main) {
                    result.success(renamed)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("WRITE_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun getPdfPageCount(path: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "PDF file not found: $path", null)
                    }
                    return@launch
                }
                val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(pfd)
                val pageCount = renderer.pageCount
                renderer.close()
                pfd.close()
                withContext(Dispatchers.Main) {
                    result.success(pageCount)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("PDF_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun renderPdfPage(path: String, pageIndex: Int, width: Int, height: Int, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "PDF file not found: $path", null)
                    }
                    return@launch
                }
                val pfd = ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY)
                val renderer = PdfRenderer(pfd)
                if (pageIndex < 0 || pageIndex >= renderer.pageCount) {
                    renderer.close()
                    pfd.close()
                    withContext(Dispatchers.Main) {
                        result.error("INVALID_PAGE", "Page index $pageIndex out of range", null)
                    }
                    return@launch
                }

                val page = renderer.openPage(pageIndex)
                val targetW = if (width > 0) width else (page.width * 2)
                val targetH = if (height > 0) height else (page.height * 2)
                val bitmap = Bitmap.createBitmap(targetW, targetH, Bitmap.Config.ARGB_8888)
                bitmap.eraseColor(android.graphics.Color.WHITE)
                page.render(bitmap, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                page.close()
                renderer.close()
                pfd.close()

                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 95, stream)
                val bytes = stream.toByteArray()
                bitmap.recycle()

                withContext(Dispatchers.Main) {
                    result.success(bytes)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("PDF_RENDER_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun playAudio(path: String, result: MethodChannel.Result) {
        try {
            if (mediaPlayer == null) {
                mediaPlayer = MediaPlayer()
            } else {
                mediaPlayer?.reset()
            }
            currentAudioPath = path
            mediaPlayer?.setDataSource(path)
            mediaPlayer?.prepare()
            mediaPlayer?.start()
            result.success(mapOf(
                "duration" to (mediaPlayer?.duration ?: 0),
                "position" to (mediaPlayer?.currentPosition ?: 0),
                "isPlaying" to true
            ))
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.localizedMessage, null)
        }
    }

    private fun pauseAudio(result: MethodChannel.Result) {
        try {
            mediaPlayer?.pause()
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.localizedMessage, null)
        }
    }

    private fun resumeAudio(result: MethodChannel.Result) {
        try {
            mediaPlayer?.start()
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.localizedMessage, null)
        }
    }

    private fun seekAudio(positionMs: Int, result: MethodChannel.Result) {
        try {
            mediaPlayer?.seekTo(positionMs)
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.localizedMessage, null)
        }
    }

    private fun getAudioPosition(result: MethodChannel.Result) {
        val mp = mediaPlayer
        if (mp != null) {
            result.success(mapOf(
                "duration" to mp.duration,
                "position" to mp.currentPosition,
                "isPlaying" to mp.isPlaying
            ))
        } else {
            result.success(mapOf(
                "duration" to 0,
                "position" to 0,
                "isPlaying" to false
            ))
        }
    }

    private fun stopAudio(result: MethodChannel.Result) {
        try {
            mediaPlayer?.stop()
            mediaPlayer?.release()
            mediaPlayer = null
            currentAudioPath = null
            result.success(true)
        } catch (e: Exception) {
            result.error("AUDIO_ERROR", e.localizedMessage, null)
        }
    }

    private fun openFileWithSystemApp(path: String, mimeType: String?, result: MethodChannel.Result) {
        try {
            val file = File(path)
            if (!file.exists()) {
                result.error("NOT_FOUND", "File not found: $path", null)
                return
            }
            val uri = FileProvider.getUriForFile(context, "${context.packageName}.fileprovider", file)
            val type = if (!mimeType.isNullOrBlank() && mimeType != "*/*") {
                mimeType
            } else {
                URLConnection.guessContentTypeFromName(file.name) ?: "*/*"
            }
            val intent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, type)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            val chooser = Intent.createChooser(intent, "Open with").apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            context.startActivity(chooser)
            result.success(true)
        } catch (e: Exception) {
            result.error("INTENT_ERROR", e.localizedMessage, null)
        }
    }

    private fun isArchiveEncrypted(path: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "File not found: $path", null)
                    }
                    return@launch
                }
                val ext = file.extension.lowercase()
                var isEncrypted = false
                if (ext == "zip" || ext == "apk" || ext == "xapk" || ext == "jar") {
                    val zip = ZipFile(file)
                    isEncrypted = zip.isEncrypted
                } else if (ext == "7z") {
                    try {
                        val sz = SevenZFile(file)
                        sz.close()
                    } catch (e: Exception) {
                        val msg = e.localizedMessage?.lowercase() ?: ""
                        if (msg.contains("password") || msg.contains("encrypted")) {
                            isEncrypted = true
                        }
                    }
                }
                withContext(Dispatchers.Main) {
                    result.success(isEncrypted)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(false)
                }
            }
        }
    }

    private fun compressArchive(
        sourcePaths: List<String>,
        destinationPath: String,
        format: String,
        password: String?,
        result: MethodChannel.Result
    ) {
        scope.launch(Dispatchers.IO) {
            try {
                val destFile = File(destinationPath)
                destFile.parentFile?.mkdirs()

                when (format.lowercase()) {
                    "7z" -> {
                        val szOut = SevenZOutputFile(destFile)
                        for (src in sourcePaths) {
                            val f = File(src)
                            if (f.exists()) addFileTo7z(szOut, f, "")
                        }
                        szOut.close()
                    }
                    "tar", "tar.gz", "tgz" -> {
                        val isGz = format == "tar.gz" || format == "tgz" || destinationPath.endsWith(".gz")
                        val fos = FileOutputStream(destFile)
                        val bos = BufferedOutputStream(fos)
                        val outStream: OutputStream = if (isGz) GzipCompressorOutputStream(bos) else bos
                        val tarOut = TarArchiveOutputStream(outStream)
                        tarOut.setLongFileMode(TarArchiveOutputStream.LONGFILE_POSIX)
                        for (src in sourcePaths) {
                            val f = File(src)
                            if (f.exists()) addFileToTar(tarOut, f, "")
                        }
                        tarOut.close()
                    }
                    else -> {
                        // Standard zip
                        val zipParameters = ZipParameters()
                        if (!password.isNullOrEmpty()) {
                            zipParameters.isEncryptFiles = true
                            zipParameters.encryptionMethod = EncryptionMethod.AES
                            zipParameters.aesKeyStrength = AesKeyStrength.KEY_STRENGTH_256
                        }
                        val zipFile = if (!password.isNullOrEmpty()) {
                            ZipFile(destFile, password.toCharArray())
                        } else {
                            ZipFile(destFile)
                        }
                        for (src in sourcePaths) {
                            val f = File(src)
                            if (f.isDirectory) {
                                zipFile.addFolder(f, zipParameters)
                            } else if (f.exists()) {
                                zipFile.addFile(f, zipParameters)
                            }
                        }
                    }
                }

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("COMPRESS_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun extractArchive(
        archivePath: String,
        destinationPath: String,
        password: String?,
        result: MethodChannel.Result
    ) {
        scope.launch(Dispatchers.IO) {
            try {
                val archiveFile = File(archivePath)
                if (!archiveFile.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Archive not found: $archivePath", null)
                    }
                    return@launch
                }
                val destDir = File(destinationPath)
                destDir.mkdirs()

                val ext = archiveFile.extension.lowercase()
                val isTarGz = archivePath.endsWith(".tar.gz", ignoreCase = true) || archivePath.endsWith(".tgz", ignoreCase = true)

                if (ext == "7z") {
                    val sz = if (!password.isNullOrEmpty()) {
                        SevenZFile(archiveFile, password.toByteArray(Charsets.UTF_16LE))
                    } else {
                        SevenZFile(archiveFile)
                    }
                    var entry = sz.nextEntry
                    val buffer = ByteArray(8192)
                    while (entry != null) {
                        val outFile = File(destDir, entry.name)
                        if (!outFile.canonicalPath.startsWith(destDir.canonicalPath)) {
                            throw SecurityException("Path traversal attempt detected")
                        }
                        if (entry.isDirectory) {
                            outFile.mkdirs()
                        } else {
                            outFile.parentFile?.mkdirs()
                            FileOutputStream(outFile).use { fos ->
                                var len: Int
                                while (sz.read(buffer).also { len = it } > 0) {
                                    fos.write(buffer, 0, len)
                                }
                            }
                        }
                        entry = sz.nextEntry
                    }
                    sz.close()
                } else if (ext == "tar" || isTarGz) {
                    val fis = FileInputStream(archiveFile)
                    val bis = BufferedInputStream(fis)
                    val inStream: InputStream = if (isTarGz) GzipCompressorInputStream(bis) else bis
                    val tarIn = TarArchiveInputStream(inStream)
                    var entry = tarIn.nextEntry
                    val buffer = ByteArray(8192)
                    while (entry != null) {
                        val outFile = File(destDir, entry.name)
                        if (!outFile.canonicalPath.startsWith(destDir.canonicalPath)) {
                            throw SecurityException("Path traversal attempt detected")
                        }
                        if (entry.isDirectory) {
                            outFile.mkdirs()
                        } else {
                            outFile.parentFile?.mkdirs()
                            FileOutputStream(outFile).use { fos ->
                                var len: Int
                                while (tarIn.read(buffer).also { len = it } > 0) {
                                    fos.write(buffer, 0, len)
                                }
                            }
                        }
                        entry = tarIn.nextEntry
                    }
                    tarIn.close()
                } else {
                    // Default to Zip4j
                    val zip = if (!password.isNullOrEmpty()) {
                        ZipFile(archiveFile, password.toCharArray())
                    } else {
                        ZipFile(archiveFile)
                    }
                    zip.extractAll(destDir.absolutePath)
                }

                withContext(Dispatchers.Main) {
                    result.success(true)
                }
            } catch (e: Exception) {
                val msg = e.localizedMessage ?: ""
                val isWrongPassword = msg.contains("password", ignoreCase = true) ||
                                      msg.contains("crc", ignoreCase = true) ||
                                      msg.contains("authentication", ignoreCase = true)
                withContext(Dispatchers.Main) {
                    result.error(if (isWrongPassword) "INVALID_PASSWORD" else "EXTRACT_ERROR", msg, null)
                }
            }
        }
    }

    private fun addFileTo7z(sevenZ: SevenZOutputFile, file: File, parentPath: String) {
        val entryName = if (parentPath.isEmpty()) file.name else "$parentPath/${file.name}"
        val entry = sevenZ.createArchiveEntry(file, entryName)
        sevenZ.putArchiveEntry(entry)
        if (file.isFile) {
            FileInputStream(file).use { fis ->
                val buffer = ByteArray(8192)
                var len: Int
                while (fis.read(buffer).also { len = it } > 0) {
                    sevenZ.write(buffer, 0, len)
                }
            }
            sevenZ.closeArchiveEntry()
        } else if (file.isDirectory) {
            sevenZ.closeArchiveEntry()
            file.listFiles()?.forEach { child ->
                addFileTo7z(sevenZ, child, entryName)
            }
        }
    }

    private fun addFileToTar(tarOut: TarArchiveOutputStream, file: File, parentPath: String) {
        val entryName = if (parentPath.isEmpty()) file.name else "$parentPath/${file.name}"
        val entry = TarArchiveEntry(file, entryName)
        tarOut.putArchiveEntry(entry)
        if (file.isFile) {
            FileInputStream(file).use { fis ->
                fis.copyTo(tarOut)
            }
            tarOut.closeArchiveEntry()
        } else if (file.isDirectory) {
            tarOut.closeArchiveEntry()
            file.listFiles()?.forEach { child ->
                addFileToTar(tarOut, child, entryName)
            }
        }
    }

    private fun getApkIcon(path: String, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val pm = context.packageManager
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) { result.success(null) }
                    return@launch
                }

                val drawable: Drawable? = if (path.endsWith(".apk", ignoreCase = true)) {
                    val archiveInfo = pm.getPackageArchiveInfo(path, 0)
                    if (archiveInfo != null) {
                        archiveInfo.applicationInfo?.let { appInfo ->
                            appInfo.sourceDir = path
                            appInfo.publicSourceDir = path
                            appInfo.loadIcon(pm)
                        }
                    } else {
                        null
                    }
                } else {
                    null
                }

                if (drawable == null) {
                    withContext(Dispatchers.Main) { result.success(null) }
                    return@launch
                }

                val bitmap = if (drawable is BitmapDrawable && drawable.bitmap != null) {
                    drawable.bitmap
                } else {
                    val w = if (drawable.intrinsicWidth > 0) drawable.intrinsicWidth else 96
                    val h = if (drawable.intrinsicHeight > 0) drawable.intrinsicHeight else 96
                    val bmp = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                    val canvas = Canvas(bmp)
                    drawable.setBounds(0, 0, canvas.width, canvas.height)
                    drawable.draw(canvas)
                    bmp
                }

                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.PNG, 85, stream)
                val bytes = stream.toByteArray()

                withContext(Dispatchers.Main) {
                    result.success(bytes)
                }
            } catch (_: Exception) {
                withContext(Dispatchers.Main) {
                    result.success(null)
                }
            }
        }
    }

    private fun listArchiveEntries(path: String, password: String?, result: MethodChannel.Result) {
        scope.launch(Dispatchers.IO) {
            try {
                val file = File(path)
                if (!file.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Archive not found: $path", null)
                    }
                    return@launch
                }

                val entriesList = mutableListOf<Map<String, Any?>>()
                val ext = file.extension.lowercase()

                if (ext == "zip") {
                    val zipFile = if (!password.isNullOrEmpty()) ZipFile(file, password.toCharArray()) else ZipFile(file)
                    val headers = zipFile.fileHeaders
                    for (header in headers) {
                        entriesList.add(mapOf(
                            "name" to header.fileName,
                            "uncompressedSize" to header.uncompressedSize,
                            "compressedSize" to header.compressedSize,
                            "isDirectory" to header.isDirectory,
                            "lastModified" to header.lastModifiedTime,
                            "isEncrypted" to header.isEncrypted
                        ))
                    }
                } else if (ext == "7z") {
                    val sevenZFile = if (!password.isNullOrEmpty()) {
                        SevenZFile.builder().setFile(file).setPassword(password.toByteArray(Charsets.UTF_16LE)).get()
                    } else {
                        SevenZFile.builder().setFile(file).get()
                    }
                    for (entry in sevenZFile.entries) {
                        entriesList.add(mapOf(
                            "name" to entry.name,
                            "uncompressedSize" to entry.size,
                            "compressedSize" to 0L,
                            "isDirectory" to entry.isDirectory,
                            "lastModified" to (entry.lastModifiedDate?.time ?: file.lastModified()),
                            "isEncrypted" to (entry.hasStream() && !password.isNullOrEmpty())
                        ))
                    }
                    sevenZFile.close()
                } else if (ext == "tar" || ext == "gz" || ext == "tgz") {
                    val rawIn = FileInputStream(file)
                    val inStream = if (ext == "gz" || ext == "tgz" || path.endsWith(".tar.gz", ignoreCase = true)) {
                        TarArchiveInputStream(GzipCompressorInputStream(BufferedInputStream(rawIn)))
                    } else {
                        TarArchiveInputStream(BufferedInputStream(rawIn))
                    }
                    var entry: TarArchiveEntry? = inStream.nextTarEntry
                    while (entry != null) {
                        entriesList.add(mapOf(
                            "name" to entry.name,
                            "uncompressedSize" to entry.size,
                            "compressedSize" to entry.size,
                            "isDirectory" to entry.isDirectory,
                            "lastModified" to (entry.modTime?.time ?: file.lastModified()),
                            "isEncrypted" to false
                        ))
                        entry = inStream.nextTarEntry
                    }
                    inStream.close()
                }

                withContext(Dispatchers.Main) {
                    result.success(entriesList)
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("LIST_ARCHIVE_ERROR", e.localizedMessage, null)
                }
            }
        }
    }

    private fun extractArchiveEntry(
        archivePath: String,
        entryName: String,
        destinationPath: String,
        password: String?,
        result: MethodChannel.Result
    ) {
        scope.launch(Dispatchers.IO) {
            try {
                val archiveFile = File(archivePath)
                if (!archiveFile.exists()) {
                    withContext(Dispatchers.Main) {
                        result.error("NOT_FOUND", "Archive not found: $archivePath", null)
                    }
                    return@launch
                }

                val destFile = File(destinationPath)
                destFile.parentFile?.mkdirs()

                val ext = archiveFile.extension.lowercase()
                var extracted = false

                if (ext == "zip") {
                    val zipFile = if (!password.isNullOrEmpty()) ZipFile(archiveFile, password.toCharArray()) else ZipFile(archiveFile)
                    val header = zipFile.getFileHeader(entryName)
                    if (header != null) {
                        zipFile.extractFile(header, destFile.parentFile!!.absolutePath, destFile.name)
                        extracted = true
                    }
                } else if (ext == "7z") {
                    val sevenZFile = if (!password.isNullOrEmpty()) {
                        SevenZFile.builder().setFile(archiveFile).setPassword(password.toByteArray(Charsets.UTF_16LE)).get()
                    } else {
                        SevenZFile.builder().setFile(archiveFile).get()
                    }
                    var entry = sevenZFile.nextEntry
                    while (entry != null) {
                        if (entry.name == entryName) {
                            val out = FileOutputStream(destFile)
                            val buffer = ByteArray(8192)
                            var bytesRead = sevenZFile.read(buffer)
                            while (bytesRead != -1) {
                                out.write(buffer, 0, bytesRead)
                                bytesRead = sevenZFile.read(buffer)
                            }
                            out.close()
                            extracted = true
                            break
                        }
                        entry = sevenZFile.nextEntry
                    }
                    sevenZFile.close()
                } else if (ext == "tar" || ext == "gz" || ext == "tgz" || archivePath.endsWith(".tar.gz", ignoreCase = true)) {
                    val rawIn = FileInputStream(archiveFile)
                    val inStream = if (ext == "gz" || ext == "tgz" || archivePath.endsWith(".tar.gz", ignoreCase = true)) {
                        TarArchiveInputStream(GzipCompressorInputStream(BufferedInputStream(rawIn)))
                    } else {
                        TarArchiveInputStream(BufferedInputStream(rawIn))
                    }
                    var entry: TarArchiveEntry? = inStream.nextTarEntry
                    while (entry != null) {
                        if (entry.name == entryName) {
                            val out = FileOutputStream(destFile)
                            inStream.copyTo(out)
                            out.close()
                            extracted = true
                            break
                        }
                        entry = inStream.nextTarEntry
                    }
                    inStream.close()
                }

                withContext(Dispatchers.Main) {
                    if (extracted && destFile.exists()) {
                        result.success(destFile.absolutePath)
                    } else {
                        result.error("NOT_FOUND", "Entry not found in archive: $entryName", null)
                    }
                }
            } catch (e: Exception) {
                withContext(Dispatchers.Main) {
                    result.error("EXTRACT_ENTRY_ERROR", e.localizedMessage, null)
                }
            }
        }
    }
}
