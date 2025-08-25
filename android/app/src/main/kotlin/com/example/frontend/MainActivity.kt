package com.example.frontend  // <<< MUST match the folder path

import android.app.Activity
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import android.os.Bundle
import android.provider.ContactsContract
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import android.content.pm.PackageManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

    private val CHANNEL = "app.contacts"
    private val REQ_PICK = 9001
    private val REQ_PERM = 9002

    private var pendingResult: MethodChannel.Result? = null
    private var pendingPickAfterPermission = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "pick" -> {
                        if (pendingResult != null) {
                            result.error("busy", "Another pick in progress", null)
                            return@setMethodCallHandler
                        }
                        pendingResult = result
                        ensureContactPermissionOrPick()
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun ensureContactPermissionOrPick() {
        val granted = ContextCompat.checkSelfPermission(
            this, android.Manifest.permission.READ_CONTACTS
        ) == PackageManager.PERMISSION_GRANTED

        if (granted) {
            launchPicker()
        } else {
            pendingPickAfterPermission = true
            ActivityCompat.requestPermissions(
                this,
                arrayOf(android.Manifest.permission.READ_CONTACTS),
                REQ_PERM
            )
        }
    }

    private fun launchPicker() {
        val intent = Intent(Intent.ACTION_PICK, ContactsContract.Contacts.CONTENT_URI)
        startActivityForResult(intent, REQ_PICK)
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQ_PERM) {
            val res = pendingResult
            if (grantResults.isNotEmpty() && grantResults[0] == PackageManager.PERMISSION_GRANTED) {
                if (pendingPickAfterPermission) {
                    pendingPickAfterPermission = false
                    launchPicker()
                }
            } else {
                pendingPickAfterPermission = false
                res?.error("perm_denied", "READ_CONTACTS denied", null)
                pendingResult = null
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)

        if (requestCode == REQ_PICK) {
            val res = pendingResult ?: return
            pendingResult = null

            if (resultCode != Activity.RESULT_OK || data == null) {
                res.error("canceled", "No contact chosen", null)
                return
            }
            val contactUri: Uri? = data.data
            if (contactUri == null) {
                res.error("no_uri", "Empty contact uri", null)
                return
            }

            var name = ""
            var phone = ""

            val cursor: Cursor? = contentResolver.query(contactUri, null, null, null, null)
            cursor?.use {
                if (it.moveToFirst()) {
                    val id = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts._ID))
                    name = it.getString(it.getColumnIndexOrThrow(ContactsContract.Contacts.DISPLAY_NAME)) ?: ""

                    val hasPhone = it.getInt(it.getColumnIndexOrThrow(ContactsContract.Contacts.HAS_PHONE_NUMBER))
                    if (hasPhone > 0) {
                        val pCur = contentResolver.query(
                            ContactsContract.CommonDataKinds.Phone.CONTENT_URI,
                            null,
                            ContactsContract.CommonDataKinds.Phone.CONTACT_ID + " = ?",
                            arrayOf(id),
                            null
                        )
                        pCur?.use { pc ->
                            if (pc.moveToFirst()) {
                                phone = pc.getString(
                                    pc.getColumnIndexOrThrow(ContactsContract.CommonDataKinds.Phone.NUMBER)
                                ) ?: ""
                            }
                        }
                    }
                }
            }

            res.success(mapOf("name" to name, "phone" to phone))
        }
    }
}
