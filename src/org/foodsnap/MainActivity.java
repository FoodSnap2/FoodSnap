package org.foodsnap;

import android.app.Activity;
import android.app.DatePickerDialog;
import android.app.TimePickerDialog;
import android.content.Intent;
import android.graphics.Bitmap;
import android.hardware.Camera;
import android.media.MediaScannerConnection;
import android.os.Bundle;
import android.view.Gravity;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.widget.Button;
import android.widget.DatePicker;
import android.widget.EditText;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.RadioButton;
import android.widget.RadioGroup;
import android.widget.TimePicker;
import android.widget.Toast;

import java.io.File;
import java.io.FileOutputStream;
import java.util.Calendar;
import java.util.List;

public class MainActivity extends Activity implements SurfaceHolder.Callback {
    private SurfaceView previewView;
    private SurfaceHolder previewHolder;
    private Camera camera;
    private int cameraId = -1;
    private boolean surfaceReady = false;
    private boolean takingPicture = false;

    private RadioGroup beforeAfterGroup;
    private RadioGroup kindGroup;
    private RadioButton beforeButton;
    private RadioButton afterButton;
    private RadioButton foodButton;
    private RadioButton weightButton;
    private EditText dateEdit;
    private Button snapButton;
    private Button gearButton;
    private ImageView lastImageView;

    private long selectedMillis;
    private boolean dateOverridden = false;

    private FoodSnapPrefs prefs;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        prefs = new FoodSnapPrefs(this);
        selectedMillis = System.currentTimeMillis();

        buildUi();

        previewHolder = previewView.getHolder();
        previewHolder.addCallback(this);
    }

    @Override
    protected void onResume() {
        super.onResume();
        prefs = new FoodSnapPrefs(this);

        applySettingsVisibility();
        if (!dateOverridden) {
            selectedMillis = System.currentTimeMillis();
        }
        updateDateText();
        loadLatestThumbnail();

        if (surfaceReady && camera == null) {
            startCamera();
        }
    }

    @Override
    protected void onPause() {
        releaseCamera();
        super.onPause();
    }

    private void buildUi() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);

        previewView = new SurfaceView(this);
        previewView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                takeFoodSnap();
            }
        });

        root.addView(previewView, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f));

        LinearLayout lower = new LinearLayout(this);
        lower.setOrientation(LinearLayout.HORIZONTAL);
        lower.setPadding(dp(6), dp(6), dp(6), dp(6));

        gearButton = new Button(this);
        gearButton.setText("\u2699");
        gearButton.setTextSize(24);
        gearButton.setGravity(Gravity.CENTER);
        gearButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(MainActivity.this, SettingsActivity.class));
            }
        });

        lower.addView(gearButton, new LinearLayout.LayoutParams(
                dp(64),
                LinearLayout.LayoutParams.MATCH_PARENT));

        LinearLayout controls = new LinearLayout(this);
        controls.setOrientation(LinearLayout.VERTICAL);
        controls.setPadding(dp(6), 0, dp(6), 0);

        beforeAfterGroup = new RadioGroup(this);
        beforeAfterGroup.setOrientation(RadioGroup.HORIZONTAL);
        beforeButton = new RadioButton(this);
        beforeButton.setText("before");
        beforeButton.setId(1001);
        afterButton = new RadioButton(this);
        afterButton.setText("after");
        afterButton.setId(1002);
        beforeAfterGroup.addView(beforeButton);
        beforeAfterGroup.addView(afterButton);
        beforeAfterGroup.check(beforeButton.getId());
        controls.addView(beforeAfterGroup, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));

        kindGroup = new RadioGroup(this);
        kindGroup.setOrientation(RadioGroup.HORIZONTAL);
        foodButton = new RadioButton(this);
        foodButton.setText("food");
        foodButton.setId(2001);
        weightButton = new RadioButton(this);
        weightButton.setText("weight");
        weightButton.setId(2002);
        kindGroup.addView(foodButton);
        kindGroup.addView(weightButton);
        kindGroup.check(foodButton.getId());
        controls.addView(kindGroup, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));

        dateEdit = new EditText(this);
        dateEdit.setSingleLine(true);
        dateEdit.setFocusable(false);
        dateEdit.setClickable(true);
        dateEdit.setTextSize(16);
        dateEdit.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                showDateTimePicker();
            }
        });
        controls.addView(dateEdit, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));

        snapButton = new Button(this);
        snapButton.setText("FoodSnap!");
        snapButton.setTextSize(22);
        snapButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                takeFoodSnap();
            }
        });
        controls.addView(snapButton, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f));

        lower.addView(controls, new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.MATCH_PARENT,
                1.0f));

        FrameLayout thumbFrame = new FrameLayout(this);
        lastImageView = new ImageView(this);
        lastImageView.setScaleType(ImageView.ScaleType.CENTER_CROP);
        lastImageView.setAdjustViewBounds(false);
        lastImageView.setBackgroundColor(0xff222222);
        lastImageView.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                startActivity(new Intent(MainActivity.this, GalleryActivity.class));
            }
        });
        thumbFrame.addView(lastImageView, new FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT));
        lower.addView(thumbFrame, new LinearLayout.LayoutParams(
                dp(112),
                LinearLayout.LayoutParams.MATCH_PARENT));

        root.addView(lower, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f));

        setContentView(root);
    }

    private void applySettingsVisibility() {
        beforeAfterGroup.setVisibility(prefs.getShowBeforeAfter() ? View.VISIBLE : View.GONE);
        kindGroup.setVisibility(prefs.getShowFoodWeight() ? View.VISIBLE : View.GONE);
    }

    private void updateDateText() {
        dateEdit.setText(prefs.formatDisplayDate(selectedMillis));
    }

    private void showDateTimePicker() {
        final Calendar cal = Calendar.getInstance();
        cal.setTimeInMillis(selectedMillis);

        DatePickerDialog dateDialog = new DatePickerDialog(
                this,
                new DatePickerDialog.OnDateSetListener() {
                    @Override
                    public void onDateSet(DatePicker view, int year, int monthOfYear, int dayOfMonth) {
                        cal.set(Calendar.YEAR, year);
                        cal.set(Calendar.MONTH, monthOfYear);
                        cal.set(Calendar.DAY_OF_MONTH, dayOfMonth);

                        TimePickerDialog timeDialog = new TimePickerDialog(
                                MainActivity.this,
                                new TimePickerDialog.OnTimeSetListener() {
                                    @Override
                                    public void onTimeSet(TimePicker view, int hourOfDay, int minute) {
                                        cal.set(Calendar.HOUR_OF_DAY, hourOfDay);
                                        cal.set(Calendar.MINUTE, minute);
                                        cal.set(Calendar.SECOND, 0);
                                        cal.set(Calendar.MILLISECOND, 0);

                                        selectedMillis = cal.getTimeInMillis();
                                        dateOverridden = true;
                                        updateDateText();
                                    }
                                },
                                cal.get(Calendar.HOUR_OF_DAY),
                                cal.get(Calendar.MINUTE),
                                true
                        );
                        timeDialog.show();
                    }
                },
                cal.get(Calendar.YEAR),
                cal.get(Calendar.MONTH),
                cal.get(Calendar.DAY_OF_MONTH)
        );

        dateDialog.show();
    }

    @Override
    public void surfaceCreated(SurfaceHolder holder) {
        surfaceReady = true;
        startCamera();
    }

    @Override
    public void surfaceChanged(SurfaceHolder holder, int format, int width, int height) {
        if (surfaceReady && camera != null) {
            try {
                camera.stopPreview();
            } catch (Exception ignored) {
            }

            try {
                camera.setPreviewDisplay(previewHolder);
                camera.startPreview();
            } catch (Exception e) {
                toast("Preview failed: " + e.getMessage());
            }
        }
    }

    @Override
    public void surfaceDestroyed(SurfaceHolder holder) {
        surfaceReady = false;
        releaseCamera();
    }

    private void startCamera() {
        if (!surfaceReady || camera != null) {
            return;
        }

        try {
            cameraId = findBackCamera();
            if (cameraId >= 0) {
                camera = Camera.open(cameraId);
            } else {
                camera = Camera.open();
                cameraId = 0;
            }

            Camera.Parameters parameters = camera.getParameters();

            List<String> focusModes = parameters.getSupportedFocusModes();
            if (focusModes != null) {
                if (focusModes.contains(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE)) {
                    parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
                } else if (focusModes.contains(Camera.Parameters.FOCUS_MODE_AUTO)) {
                    parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
                }
            }

            parameters.setJpegQuality(92);
            parameters.setRotation(getJpegRotation(cameraId));
            camera.setParameters(parameters);

            camera.setPreviewDisplay(previewHolder);
            camera.setDisplayOrientation(getDisplayOrientation(cameraId));
            camera.startPreview();
        } catch (Exception e) {
            toast("Camera failed: " + e.getMessage());
            releaseCamera();
        }
    }

    private int findBackCamera() {
        try {
            int count = Camera.getNumberOfCameras();
            Camera.CameraInfo info = new Camera.CameraInfo();

            for (int i = 0; i < count; i++) {
                Camera.getCameraInfo(i, info);
                if (info.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                    return i;
                }
            }
        } catch (Exception ignored) {
        }

        return -1;
    }

    private int getDisplayOrientation(int id) {
        try {
            Camera.CameraInfo info = new Camera.CameraInfo();
            Camera.getCameraInfo(id, info);

            int rotation = getWindowManager().getDefaultDisplay().getRotation();
            int degrees = rotationToDegrees(rotation);

            int result;
            if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                result = (info.orientation + degrees) % 360;
                result = (360 - result) % 360;
            } else {
                result = (info.orientation - degrees + 360) % 360;
            }

            return result;
        } catch (Exception e) {
            return 90;
        }
    }

    private int getJpegRotation(int id) {
        try {
            Camera.CameraInfo info = new Camera.CameraInfo();
            Camera.getCameraInfo(id, info);

            int rotation = getWindowManager().getDefaultDisplay().getRotation();
            int degrees = rotationToDegrees(rotation);

            if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
                return (info.orientation - degrees + 360) % 360;
            } else {
                return (info.orientation + degrees) % 360;
            }
        } catch (Exception e) {
            return 90;
        }
    }

    private int rotationToDegrees(int rotation) {
        if (rotation == Surface.ROTATION_90) {
            return 90;
        }
        if (rotation == Surface.ROTATION_180) {
            return 180;
        }
        if (rotation == Surface.ROTATION_270) {
            return 270;
        }
        return 0;
    }

    private void takeFoodSnap() {
        if (takingPicture || camera == null) {
            return;
        }

        takingPicture = true;

        try {
            String focusMode = camera.getParameters().getFocusMode();
            if (Camera.Parameters.FOCUS_MODE_AUTO.equals(focusMode)
                    || Camera.Parameters.FOCUS_MODE_MACRO.equals(focusMode)) {
                try {
                    camera.autoFocus(new Camera.AutoFocusCallback() {
                        @Override
                        public void onAutoFocus(boolean success, Camera cam) {
                            reallyTakePicture();
                        }
                    });
                    return;
                } catch (Exception ignored) {
                    reallyTakePicture();
                    return;
                }
            }

            reallyTakePicture();
        } catch (Exception e) {
            toast("Snap failed: " + e.getMessage());
            takingPicture = false;
        }
    }

    private void reallyTakePicture() {
        try {
            camera.takePicture(null, null, new Camera.PictureCallback() {
                @Override
                public void onPictureTaken(byte[] data, Camera cam) {
                    savePictureAndExit(data);
                }
            });
        } catch (Exception e) {
            toast("Photo failed: " + e.getMessage());
            takingPicture = false;
        }
    }

    private void savePictureAndExit(byte[] data) {
        long captureMillis = dateOverridden ? selectedMillis : System.currentTimeMillis();
        String beforeAfter = selectedBeforeAfter();
        String kind = selectedKind();

        try {
            File dir = ImageFiles.getDayFolder(this, captureMillis);
            if (!dir.exists() && !dir.mkdirs()) {
                throw new Exception("Could not create " + dir.getAbsolutePath());
            }

            String name = prefs.buildFileName(captureMillis, beforeAfter, kind);
            File outFile = uniqueFile(dir, name);

            FileOutputStream out = new FileOutputStream(outFile);
            out.write(data);
            out.flush();
            out.close();

            MediaScannerConnection.scanFile(
                    this,
                    new String[] { outFile.getAbsolutePath() },
                    new String[] { "image/jpeg" },
                    null
            );

            toast("Saved " + outFile.getName());
            releaseCamera();
            finish();
        } catch (Exception e) {
            toast("Save failed: " + e.getMessage());
            takingPicture = false;
            try {
                if (camera != null) {
                    camera.startPreview();
                }
            } catch (Exception ignored) {
            }
        }
    }

    private String selectedBeforeAfter() {
        if (!prefs.getShowBeforeAfter()) {
            return "before";
        }

        int id = beforeAfterGroup.getCheckedRadioButtonId();
        if (id == afterButton.getId()) {
            return "after";
        }
        return "before";
    }

    private String selectedKind() {
        if (!prefs.getShowFoodWeight()) {
            return "food";
        }

        int id = kindGroup.getCheckedRadioButtonId();
        if (id == weightButton.getId()) {
            return "weight";
        }
        return "food";
    }

    private File uniqueFile(File dir, String name) {
        File file = new File(dir, name);
        if (!file.exists()) {
            return file;
        }

        int dot = name.lastIndexOf('.');
        String baseName;
        String ext;

        if (dot > 0) {
            baseName = name.substring(0, dot);
            ext = name.substring(dot);
        } else {
            baseName = name;
            ext = ".jpg";
        }

        for (int i = 2; i < 10000; i++) {
            File candidate = new File(dir, baseName + "_" + i + ext);
            if (!candidate.exists()) {
                return candidate;
            }
        }

        return new File(dir, baseName + "_" + System.currentTimeMillis() + ext);
    }

    private void loadLatestThumbnail() {
        File latest = ImageFiles.latestImage(this);
        if (latest == null) {
            lastImageView.setImageBitmap(null);
            return;
        }

        Bitmap bm = ImageFiles.decodeSampledBitmap(
                latest.getAbsolutePath(),
                dp(112),
                dp(112));

        lastImageView.setImageBitmap(bm);
    }

    private void releaseCamera() {
        if (camera != null) {
            try {
                camera.cancelAutoFocus();
            } catch (Exception ignored) {
            }

            try {
                camera.stopPreview();
            } catch (Exception ignored) {
            }

            try {
                camera.release();
            } catch (Exception ignored) {
            }

            camera = null;
        }

        takingPicture = false;
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }

    private void toast(String msg) {
        Toast.makeText(this, msg, Toast.LENGTH_SHORT).show();
    }
}
