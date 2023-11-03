package com.cloudchewie.otp.activity;

import android.app.Activity;
import android.net.Uri;
import android.os.Bundle;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.ImageView;
import android.widget.Toast;

import androidx.appcompat.widget.AppCompatButton;

import com.cloudchewie.otp.R;
import com.cloudchewie.otp.entity.OtpToken;
import com.cloudchewie.otp.util.authenticator.OtpTokenParser;
import com.cloudchewie.otp.util.authenticator.TokenImageUtil;
import com.cloudchewie.otp.util.database.LocalStorage;
import com.cloudchewie.otp.util.enumeration.EventBusCode;
import com.cloudchewie.otp.util.enumeration.OtpTokenType;
import com.cloudchewie.ui.custom.IDialog;
import com.cloudchewie.ui.custom.IToast;
import com.cloudchewie.ui.custom.TitleBar;
import com.cloudchewie.ui.item.InputItem;
import com.cloudchewie.ui.item.RadioItem;
import com.cloudchewie.util.ui.StatusBarUtil;
import com.jeremyliao.liveeventbus.LiveEventBus;
import com.scwang.smart.refresh.layout.api.RefreshLayout;

import java.io.UnsupportedEncodingException;
import java.net.URLEncoder;
import java.util.Arrays;
import java.util.Locale;

public class TokenDetailActivity extends BaseActivity implements View.OnClickListener, TextWatcher {
    RefreshLayout swipeRefreshLayout;
    ImageView logoView;
    InputItem issuerItem;
    InputItem accountItem;
    InputItem secretItem;
    InputItem intervalItem;
    RadioItem typeItem;
    RadioItem digitsItem;
    RadioItem algorithmItem;
    InputItem counterItem;
    String imageUrl;
    OtpToken paramToken;
    AppCompatButton deleteButton;
    public static String EXTRA_TOKEN_ID = "token_id";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        StatusBarUtil.setStatusBarMarginTop(this);
        setContentView(R.layout.activity_detail);
        ((TitleBar) findViewById(R.id.activity_authenticator_detail_titlebar)).setLeftButtonClickListener(v -> finish());
        ((TitleBar) findViewById(R.id.activity_authenticator_detail_titlebar)).setRightButtonClickListener(v -> confirm());
        logoView = findViewById(R.id.activity_authenticator_detail_icon);
        issuerItem = findViewById(R.id.activity_authenticator_detail_issuer);
        accountItem = findViewById(R.id.activity_authenticator_detail_account);
        secretItem = findViewById(R.id.activity_authenticator_detail_secret);
        intervalItem = findViewById(R.id.activity_authenticator_detail_interval);
        typeItem = findViewById(R.id.activity_authenticator_detail_type);
        digitsItem = findViewById(R.id.activity_authenticator_detail_digits);
        algorithmItem = findViewById(R.id.activity_authenticator_detail_algorithm);
        counterItem = findViewById(R.id.activity_authenticator_detail_counter);
        deleteButton = findViewById(R.id.activity_authenticator_detail_delete);
        deleteButton.setOnClickListener(this);
        initSwipeRefresh();
        paramToken = LocalStorage.getAppDatabase().otpTokenDao().get(getIntent().getLongExtra(EXTRA_TOKEN_ID, 0L));
        changeState();
        changeCounterVisibility();
        typeItem.setOnIndexChangedListener((radioButton, index) -> changeCounterVisibility());
        issuerItem.getEditText().addTextChangedListener(this);
        accountItem.getEditText().addTextChangedListener(this);
    }

    void changeCounterVisibility() {
        if (typeItem.getSelectedIndex() == 0) {
            counterItem.setVisibility(View.GONE);
            intervalItem.setRadiusEnbale(false, true);
        } else {
            counterItem.setVisibility(View.VISIBLE);
            intervalItem.setRadiusEnbale(false, false);
        }
    }

    void changeState() {
        if (paramToken != null) {
            issuerItem.getEditText().setText(paramToken.getIssuer());
            accountItem.getEditText().setText(paramToken.getAccount());
            secretItem.getEditText().setText(paramToken.getSecret());
            intervalItem.getEditText().setText(String.valueOf(paramToken.getPeriod()));
            typeItem.setSelectedIndex(paramToken.getTokenType() == OtpTokenType.TOTP ? 0 : 1);
            digitsItem.setSelectedIndex(paramToken.getDigits() - 5);
            algorithmItem.setSelectedIndex(Arrays.asList(getResources().getStringArray(R.array.auth_algorithms)).indexOf(paramToken.getAlgorithm()));
            typeItem.setEnabled(false);
            digitsItem.setEnabled(false);
            algorithmItem.setEnabled(false);
            intervalItem.getEditText().setEnabled(false);
            TokenImageUtil.setTokenImage(logoView, paramToken);
            ((TitleBar) findViewById(R.id.activity_authenticator_detail_titlebar)).setTitle(getString(R.string.title_detail_token));
        } else {
            intervalItem.getEditText().setText(R.string.default_interval);
            deleteButton.setVisibility(View.GONE);
            ((TitleBar) findViewById(R.id.activity_authenticator_detail_titlebar)).setTitle(getString(R.string.title_add_token));
        }
    }

    private void confirm() {
        if (paramToken != null) {
            paramToken.setIssuer(Uri.decode(issuerItem.getText()));
            paramToken.setAccount(Uri.decode(accountItem.getText()));
            paramToken.setSecret(Uri.decode(secretItem.getText()));
            LocalStorage.getAppDatabase().otpTokenDao().update(paramToken);
            setResult(Activity.RESULT_OK);
            finish();
            LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("");
        } else {
            String issuer = Uri.decode(issuerItem.getText());
            String account = Uri.decode(accountItem.getText());
            String secret = Uri.decode(secretItem.getText());
            Integer interval = Integer.parseInt(Uri.decode(intervalItem.getText()));
            String algorithm = (String) getResources().getTextArray(R.array.auth_algorithms)[algorithmItem.getSelectedIndex()];
            Integer digits = Integer.parseInt((String) getResources().getTextArray(R.array.auth_digits)[digitsItem.getSelectedIndex()]);
            boolean isHotp = Boolean.parseBoolean((String) getResources().getTextArray(R.array.auth_type)[typeItem.getSelectedIndex()]);
            String uri = String.format(Locale.US,
                    "otpauth://%sotp/%s:%s?secret=%s&algorithm=%s&digits=%d&period=%d",
                    isHotp ? "h" : "t", issuer, account,
                    secret, algorithm, digits, interval);
            if (isHotp) {
                Integer counter = Integer.parseInt(counterItem.getText());
                uri += String.format(Locale.US, "&counter=%d", counter);
            }
            if (imageUrl != null) {
                try {
                    String enc = URLEncoder.encode(imageUrl, "utf-8");
                    uri += String.format(Locale.US, "&image=%s", enc);
                } catch (UnsupportedEncodingException e) {
                    e.printStackTrace();
                }
            }
            LocalStorage.getAppDatabase().otpTokenDao().insert(OtpTokenParser.createFromUri(Uri.parse(uri)));
            setResult(Activity.RESULT_OK);
            LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("");
            finish();
        }
    }

    void initSwipeRefresh() {
        swipeRefreshLayout = findViewById(R.id.activity_authenticator_detail_swipe_refresh);
        swipeRefreshLayout.setEnableOverScrollDrag(true);
        swipeRefreshLayout.setEnableOverScrollBounce(true);
        swipeRefreshLayout.setEnableLoadMore(false);
        swipeRefreshLayout.setEnablePureScrollMode(true);
    }

    @Override
    public void onClick(View view) {
        if (view == deleteButton) {
            if (paramToken == null)
                return;
            IDialog dialog = new IDialog(this);
            dialog.setTitle(getString(R.string.dialog_title_delete_token));
            dialog.setMessage(getString(R.string.dialog_content_delete_token));
            dialog.setOnClickBottomListener(new IDialog.OnClickBottomListener() {
                @Override
                public void onPositiveClick() {
                    LocalStorage.getAppDatabase().otpTokenDao().deleteById(paramToken.getId());
                    finish();
                    LiveEventBus.get(EventBusCode.CHANGE_TOKEN.getKey()).post("");
                    IToast.makeTextBottom(TokenDetailActivity.this, getString(R.string.delete_token_success), Toast.LENGTH_SHORT).show();
                }

                @Override
                public void onNegtiveClick() {
                }

                @Override
                public void onCloseClick() {
                }
            });
            dialog.show();
        }
    }

    @Override
    public void beforeTextChanged(CharSequence charSequence, int i, int i1, int i2) {

    }

    @Override
    public void onTextChanged(CharSequence charSequence, int i, int i1, int i2) {
        OtpToken temp = new OtpToken();
        temp.setAccount(accountItem.getText());
        temp.setIssuer(issuerItem.getText());
        TokenImageUtil.setTokenImage(logoView, temp);
    }

    @Override
    public void afterTextChanged(Editable editable) {

    }
}