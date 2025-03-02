package com.follow.clash.ene.models

data class Package(
    val packageName: String,
    val label: String,
    val isSystem: Boolean,
    val firstInstallTime: Long,
)
