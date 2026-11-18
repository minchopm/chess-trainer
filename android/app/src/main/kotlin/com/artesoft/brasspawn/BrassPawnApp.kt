package com.artesoft.brasspawn

import android.app.Application
import android.content.res.Configuration
import com.artesoft.brasspawn.data.Strings
import com.artesoft.brasspawn.match.L

class BrassPawnApp : Application() {
    override fun onCreate() {
        super.onCreate()
        Strings.load(this)
        // The rules and the training layer build their own sentences: they ask here for the words.
        L.resolver = Strings::lookup
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        Strings.load(this, newConfig.locales)
    }
}
