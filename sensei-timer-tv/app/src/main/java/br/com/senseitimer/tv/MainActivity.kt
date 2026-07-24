package br.com.senseitimer.tv

import android.annotation.SuppressLint
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.view.KeyEvent
import android.view.View
import android.view.inputmethod.EditorInfo
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebSettings
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.Button
import android.widget.EditText
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private val PREFS = "sensei_tv_prefs"
    private val KEY_UID = "academy_uid"
    private val BASE_URL = "https://sensei-manager-d64c0.web.app/display.html"

    private lateinit var setupLayout: LinearLayout
    private lateinit var webView: WebView
    private lateinit var uidInput: EditText
    private lateinit var btnConectar: Button
    private lateinit var btnRedefinir: Button
    private lateinit var tvErro: TextView

    @SuppressLint("SetJavaScriptEnabled")
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)

        setupLayout = findViewById(R.id.setup_layout)
        webView = findViewById(R.id.webview)
        uidInput = findViewById(R.id.uid_input)
        btnConectar = findViewById(R.id.btn_conectar)
        btnRedefinir = findViewById(R.id.btn_redefinir)
        tvErro = findViewById(R.id.tv_erro)

        configWebView()

        // Deep link recebido (senseitimer://configure?uid=XXX)
        handleDeepLink(intent)

        // Verificar UID salvo
        val savedUid = getSavedUid()
        if (savedUid != null) {
            loadTimer(savedUid)
        } else {
            showSetup()
        }

        btnConectar.setOnClickListener { tryConnect() }

        uidInput.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_DONE) {
                tryConnect()
                true
            } else false
        }

        btnRedefinir.setOnClickListener {
            clearUid()
            webView.visibility = View.GONE
            btnRedefinir.visibility = View.GONE
            setupLayout.visibility = View.VISIBLE
            uidInput.setText("")
            tvErro.visibility = View.GONE
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleDeepLink(intent)
    }

    private fun handleDeepLink(intent: Intent?) {
        if (intent?.action == Intent.ACTION_VIEW) {
            val uri: Uri? = intent.data
            val uid = uri?.getQueryParameter("uid")
            if (!uid.isNullOrBlank()) {
                saveUid(uid)
                loadTimer(uid)
            }
        }
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun configWebView() {
        webView.settings.apply {
            javaScriptEnabled = true
            domStorageEnabled = true
            databaseEnabled = true
            cacheMode = WebSettings.LOAD_DEFAULT
            mediaPlaybackRequiresUserGesture = false
            useWideViewPort = true
            loadWithOverviewMode = true
        }
        webView.webViewClient = object : WebViewClient() {
            override fun shouldOverrideUrlLoading(view: WebView, request: WebResourceRequest) = false
        }
        webView.webChromeClient = WebChromeClient()
    }

    private fun showSetup() {
        setupLayout.visibility = View.VISIBLE
        webView.visibility = View.GONE
        btnRedefinir.visibility = View.GONE
    }

    private fun loadTimer(uid: String) {
        setupLayout.visibility = View.GONE
        btnRedefinir.visibility = View.VISIBLE
        webView.visibility = View.VISIBLE
        webView.loadUrl("$BASE_URL?s=$uid")
    }

    private fun tryConnect() {
        val uid = uidInput.text.toString().trim()
        if (uid.length < 10) {
            tvErro.text = "Código inválido. Copie o código completo do seu celular/computador."
            tvErro.visibility = View.VISIBLE
            return
        }
        tvErro.visibility = View.GONE
        saveUid(uid)
        loadTimer(uid)
    }

    private fun getSavedUid(): String? =
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).getString(KEY_UID, null)

    private fun saveUid(uid: String) =
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().putString(KEY_UID, uid).apply()

    private fun clearUid() =
        getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit().remove(KEY_UID).apply()

    override fun onKeyDown(keyCode: Int, event: KeyEvent?): Boolean {
        if (keyCode == KeyEvent.KEYCODE_BACK && webView.visibility == View.VISIBLE && webView.canGoBack()) {
            webView.goBack()
            return true
        }
        return super.onKeyDown(keyCode, event)
    }
}
