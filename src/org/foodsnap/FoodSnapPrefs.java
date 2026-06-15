package org.foodsnap;

import android.content.Context;
import android.content.SharedPreferences;

import java.io.File;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.Locale;

public class FoodSnapPrefs {
    public static final String PREFS_NAME = "FoodSnapSettings";

    public static final String KEY_SAVE_FOLDER = "save_folder";
    public static final String KEY_DATE_FORMAT = "date_format";
    public static final String KEY_FILENAME_FORMAT = "filename_format";
    public static final String KEY_SHOW_BEFORE_AFTER = "show_before_after";
    public static final String KEY_SHOW_FOOD_WEIGHT = "show_food_weight";

    public static final String DEFAULT_SAVE_FOLDER = "FoodSnap";
    public static final String DEFAULT_DATE_FORMAT = "yyyy-MM-dd HH:mm";
    public static final String DEFAULT_FILENAME_FORMAT =
            "{yyyy}-{MM}-{dd}_{HH}-{mm}-{ss}_{beforeafter}_{kind}.jpg";

    private final SharedPreferences prefs;

    public FoodSnapPrefs(Context context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE);
    }

    public String getSaveFolderName() {
        return cleanFolderName(prefs.getString(KEY_SAVE_FOLDER, DEFAULT_SAVE_FOLDER));
    }

    public String getDateFormat() {
        String value = prefs.getString(KEY_DATE_FORMAT, DEFAULT_DATE_FORMAT);
        if (value == null || value.trim().length() == 0) {
            return DEFAULT_DATE_FORMAT;
        }
        return value.trim();
    }

    public String getFileNameFormat() {
        String value = prefs.getString(KEY_FILENAME_FORMAT, DEFAULT_FILENAME_FORMAT);
        if (value == null || value.trim().length() == 0) {
            return DEFAULT_FILENAME_FORMAT;
        }
        return value.trim();
    }

    public boolean getShowBeforeAfter() {
        return prefs.getBoolean(KEY_SHOW_BEFORE_AFTER, true);
    }

    public boolean getShowFoodWeight() {
        return prefs.getBoolean(KEY_SHOW_FOOD_WEIGHT, true);
    }

    public void saveSettings(String saveFolder, String dateFormat, String filenameFormat,
                             boolean showBeforeAfter, boolean showFoodWeight) {
        SharedPreferences.Editor editor = prefs.edit();
        editor.putString(KEY_SAVE_FOLDER, cleanFolderName(saveFolder));
        editor.putString(KEY_DATE_FORMAT, nonEmpty(dateFormat, DEFAULT_DATE_FORMAT));
        editor.putString(KEY_FILENAME_FORMAT, nonEmpty(filenameFormat, DEFAULT_FILENAME_FORMAT));
        editor.putBoolean(KEY_SHOW_BEFORE_AFTER, showBeforeAfter);
        editor.putBoolean(KEY_SHOW_FOOD_WEIGHT, showFoodWeight);
        editor.commit();
    }

    public void resetDefaults() {
        SharedPreferences.Editor editor = prefs.edit();
        editor.clear();
        editor.commit();
    }

    public String formatDisplayDate(long millis) {
        try {
            return new SimpleDateFormat(getDateFormat(), Locale.US).format(new Date(millis));
        } catch (Exception e) {
            return new SimpleDateFormat(DEFAULT_DATE_FORMAT, Locale.US).format(new Date(millis));
        }
    }

    public String formatDayFolder(long millis) {
        return new SimpleDateFormat("yyyy-MM-dd", Locale.US).format(new Date(millis));
    }

    public String buildFileName(long millis, String beforeAfter, String kind) {
        Date date = new Date(millis);
        String pattern = getFileNameFormat();

        String out = pattern;
        out = out.replace("{yyyy}", fmt(date, "yyyy"));
        out = out.replace("{MM}", fmt(date, "MM"));
        out = out.replace("{dd}", fmt(date, "dd"));
        out = out.replace("{HH}", fmt(date, "HH"));
        out = out.replace("{mm}", fmt(date, "mm"));
        out = out.replace("{ss}", fmt(date, "ss"));
        out = out.replace("{date}", fmt(date, "yyyy-MM-dd"));
        out = out.replace("{time}", fmt(date, "HH-mm-ss"));
        out = out.replace("{datetime}", fmt(date, "yyyy-MM-dd_HH-mm-ss"));
        out = out.replace("{beforeafter}", cleanFilePart(beforeAfter));
        out = out.replace("{kind}", cleanFilePart(kind));

        out = cleanFileName(out);

        if (!out.toLowerCase(Locale.US).endsWith(".jpg")
                && !out.toLowerCase(Locale.US).endsWith(".jpeg")) {
            out = out + ".jpg";
        }

        if (out.equals(".jpg") || out.equals(".jpeg")) {
            out = fmt(date, "yyyy-MM-dd_HH-mm-ss") + ".jpg";
        }

        return out;
    }

    public static String cleanFolderName(String raw) {
        String s = nonEmpty(raw, DEFAULT_SAVE_FOLDER);
        s = s.replace('\\', '/');
        s = s.replace("..", "");
        while (s.startsWith("/")) {
            s = s.substring(1);
        }
        while (s.endsWith("/")) {
            s = s.substring(0, s.length() - 1);
        }
        s = s.replace(':', '_');
        if (s.trim().length() == 0) {
            s = DEFAULT_SAVE_FOLDER;
        }
        return s;
    }

    public static String cleanFileName(String raw) {
        String s = nonEmpty(raw, "photo.jpg");
        char[] bad = new char[] {'\\', '/', ':', '*', '?', '"', '<', '>', '|'};
        for (int i = 0; i < bad.length; i++) {
            s = s.replace(bad[i], '_');
        }
        s = s.trim();
        if (s.length() == 0) {
            s = "photo.jpg";
        }
        return s;
    }

    public static String cleanFilePart(String raw) {
        String s = nonEmpty(raw, "x").toLowerCase(Locale.US);
        return cleanFileName(s).replace(' ', '_');
    }

    public static String nonEmpty(String raw, String fallback) {
        if (raw == null) {
            return fallback;
        }
        String s = raw.trim();
        if (s.length() == 0) {
            return fallback;
        }
        return s;
    }

    private static String fmt(Date date, String pattern) {
        return new SimpleDateFormat(pattern, Locale.US).format(date);
    }
}
