# Stripe push provisioning - ignore missing optional classes
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivity$g
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Args
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter$Error
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningActivityStarter
-dontwarn com.stripe.android.pushProvisioning.PushProvisioningEphemeralKeyProvider
-dontwarn kotlinx.parcelize.Parceler$DefaultImpls
-dontwarn kotlinx.parcelize.Parceler
-dontwarn kotlinx.parcelize.Parcelize
# Keep Stripe classes
-keep class com.stripe.** { *; }

# Web3Auth & Web3 libraries
-dontwarn com.web3auth.**
-dontwarn org.bouncycastle.**
-dontwarn org.web3j.**
-keep class com.web3auth.** { *; }

# Flutter plugins
-dontwarn io.flutter.plugins.**

# Missing optional classes identified by R8
-dontwarn com.stripe.android.pushProvisioning.EphemeralKeyUpdateListener
-dontwarn java.beans.ConstructorProperties
-dontwarn java.beans.Transient
-dontwarn org.slf4j.impl.StaticLoggerBinder
