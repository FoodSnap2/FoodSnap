package org.foodsnap;

import android.app.Activity;
import android.app.AlertDialog;
import android.os.Bundle;
import android.text.InputType;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.CheckBox;
import android.widget.EditText;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;
import android.widget.Toast;

public class SettingsActivity extends Activity {
    private FoodSnapPrefs prefs;

    private EditText saveFolderEdit;
    private EditText dateFormatEdit;
    private EditText filenameFormatEdit;
    private CheckBox showBeforeAfterBox;
    private CheckBox showFoodWeightBox;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        prefs = new FoodSnapPrefs(this);
        buildUi();
        loadValues();
    }

    private void buildUi() {
        ScrollView scroll = new ScrollView(this);

        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);
        root.setPadding(dp(12), dp(12), dp(12), dp(12));
        scroll.addView(root);

        TextView title = new TextView(this);
        title.setText("FoodSnap Settings");
        title.setTextSize(24);
        title.setGravity(Gravity.CENTER_HORIZONTAL);
        root.addView(title, lp());

        addHelp(root,
                "Photos are saved under Pictures/<save folder>/<yyyy-MM-dd>/");

        root.addView(label("Save folder name"));
        saveFolderEdit = singleLineEdit();
        root.addView(saveFolderEdit, lp());

        root.addView(label("Date display format"));
        dateFormatEdit = singleLineEdit();
        root.addView(dateFormatEdit, lp());

        addHelp(root,
                "Example: yyyy-MM-dd HH:mm");

        root.addView(label("File name format"));
        filenameFormatEdit = singleLineEdit();
        root.addView(filenameFormatEdit, lp());

        addHelp(root,
                "Placeholders: {yyyy} {MM} {dd} {HH} {mm} {ss} {date} {time} {datetime} {beforeafter} {kind}");

        showBeforeAfterBox = new CheckBox(this);
        showBeforeAfterBox.setText("Show before/after radio buttons");
        root.addView(showBeforeAfterBox, lp());

        showFoodWeightBox = new CheckBox(this);
        showFoodWeightBox.setText("Show food/weight radio buttons");
        root.addView(showFoodWeightBox, lp());

        Button saveButton = new Button(this);
        saveButton.setText("Save settings");
        saveButton.setTextSize(20);
        saveButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                saveAndFinish();
            }
        });
        root.addView(saveButton, lp());

        Button defaultsButton = new Button(this);
        defaultsButton.setText("Reset defaults");
        defaultsButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                confirmReset();
            }
        });
        root.addView(defaultsButton, lp());

        Button cancelButton = new Button(this);
        cancelButton.setText("Cancel");
        cancelButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
            }
        });
        root.addView(cancelButton, lp());

        setContentView(scroll);
    }

    private void loadValues() {
        saveFolderEdit.setText(prefs.getSaveFolderName());
        dateFormatEdit.setText(prefs.getDateFormat());
        filenameFormatEdit.setText(prefs.getFileNameFormat());
        showBeforeAfterBox.setChecked(prefs.getShowBeforeAfter());
        showFoodWeightBox.setChecked(prefs.getShowFoodWeight());
    }

    private void saveAndFinish() {
        prefs.saveSettings(
                saveFolderEdit.getText().toString(),
                dateFormatEdit.getText().toString(),
                filenameFormatEdit.getText().toString(),
                showBeforeAfterBox.isChecked(),
                showFoodWeightBox.isChecked()
        );

        Toast.makeText(this, "Settings saved", Toast.LENGTH_SHORT).show();
        finish();
    }

    private void confirmReset() {
        new AlertDialog.Builder(this)
                .setTitle("Reset defaults?")
                .setMessage("This will restore the default FoodSnap settings.")
                .setPositiveButton("Reset", new android.content.DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(android.content.DialogInterface dialog, int which) {
                        prefs.resetDefaults();
                        loadValues();
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private TextView label(String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(16);
        view.setPadding(0, dp(12), 0, 0);
        return view;
    }

    private void addHelp(LinearLayout root, String text) {
        TextView view = new TextView(this);
        view.setText(text);
        view.setTextSize(13);
        view.setPadding(0, dp(2), 0, dp(4));
        root.addView(view, lp());
    }

    private EditText singleLineEdit() {
        EditText edit = new EditText(this);
        edit.setSingleLine(true);
        edit.setInputType(InputType.TYPE_CLASS_TEXT);
        return edit;
    }

    private LinearLayout.LayoutParams lp() {
        return new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }
}
