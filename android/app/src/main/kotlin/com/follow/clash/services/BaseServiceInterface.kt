package com.follow.clash.ene.services

import com.follow.clash.ene.models.VpnOptions

interface BaseServiceInterface {

    fun start(options: VpnOptions): Int

    fun stop()

    suspend fun startForeground(title: String, content: String)
}