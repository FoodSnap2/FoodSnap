package org.foodsnap;

import android.app.Activity;
import android.app.AlertDialog;
import android.content.DialogInterface;
import android.content.Intent;
import android.content.SharedPreferences;
import android.graphics.Bitmap;
import android.media.MediaScannerConnection;
import android.os.Bundle;
import android.view.Gravity;
import android.view.View;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ImageView;
import android.widget.LinearLayout;
import android.widget.ScrollView;
import android.widget.TextView;

import java.io.File;
import java.util.ArrayList;

public class GalleryActivity extends Activity {
    private LinearLayout list;
    private SharedPreferences comments;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        comments = getSharedPreferences("FoodSnapComments", MODE_PRIVATE);
        buildShell();
    }

    @Override
    protected void onResume() {
        super.onResume();
        reloadList();
    }

    private void buildShell() {
        LinearLayout root = new LinearLayout(this);
        root.setOrientation(LinearLayout.VERTICAL);

        LinearLayout top = new LinearLayout(this);
        top.setOrientation(LinearLayout.HORIZONTAL);
        top.setGravity(Gravity.CENTER_VERTICAL);
        top.setPadding(dp(6), dp(6), dp(6), dp(6));

        Button back = new Button(this);
        back.setText("Back");
        back.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                finish();
            }
        });
        top.addView(back, new LinearLayout.LayoutParams(
                dp(90),
                LinearLayout.LayoutParams.WRAP_CONTENT));

        TextView title = new TextView(this);
        title.setText("FoodSnap Gallery");
        title.setTextSize(22);
        title.setGravity(Gravity.CENTER_VERTICAL);
        top.addView(title, new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1.0f));

        root.addView(top, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT));

        ScrollView scroll = new ScrollView(this);
        list = new LinearLayout(this);
        list.setOrientation(LinearLayout.VERTICAL);
        scroll.addView(list);

        root.addView(scroll, new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1.0f));

        setContentView(root);
    }

    private void reloadList() {
        list.removeAllViews();

        ArrayList<File> files = ImageFiles.listImagesNewestFirst(this);

        if (files.size() == 0) {
            TextView empty = new TextView(this);
            empty.setText("No FoodSnap images yet.");
            empty.setTextSize(18);
            empty.setGravity(Gravity.CENTER_HORIZONTAL);
            empty.setPadding(dp(12), dp(40), dp(12), dp(12));
            list.addView(empty, new LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT));
            return;
        }

        for (int i = 0; i < files.size(); i++) {
            list.addView(rowFor(files.get(i)));
        }
    }

    private View rowFor(final File file) {
        LinearLayout row = new LinearLayout(this);
        row.setOrientation(LinearLayout.HORIZONTAL);
        row.setPadding(dp(8), dp(8), dp(8), dp(8));
        row.setGravity(Gravity.CENTER_VERTICAL);

        ImageView img = new ImageView(this);
        img.setScaleType(ImageView.ScaleType.CENTER_CROP);
        img.setBackgroundColor(0xff222222);

        Bitmap bm = ImageFiles.decodeSampledBitmap(
                file.getAbsolutePath(),
                dp(96),
                dp(96));
        img.setImageBitmap(bm);

        row.addView(img, new LinearLayout.LayoutParams(dp(96), dp(96)));

        TextView text = new TextView(this);
        text.setText(fileText(file));
        text.setPadding(dp(10), 0, 0, 0);
        text.setTextSize(14);
        row.addView(text, new LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1.0f));

        View.OnClickListener showListener = new View.OnClickListener() {
            @Override
            public void onClick(View view) {
                showImage(file);
            }
        };

        View.OnLongClickListener longClickListener = new View.OnLongClickListener() {
            @Override
            public boolean onLongClick(View view) {
                showContextMenu(file);
                return true;
            }
        };

        row.setOnClickListener(showListener);
        img.setOnClickListener(showListener);
        row.setOnLongClickListener(longClickListener);
        img.setOnLongClickListener(longClickListener);

        return row;
    }

    private String fileText(File file) {
        StringBuilder sb = new StringBuilder();
        sb.append(file.getName());
        sb.append("\n");
        sb.append(file.getParentFile().getName());

        String comment = comments.getString(file.getAbsolutePath(), "");
        if (comment != null && comment.trim().length() > 0) {
            sb.append("\n");
            sb.append(comment.trim());
        }

        return sb.toString();
    }

    private void showContextMenu(final File file) {
        final String[] choices = new String[] { "Show", "Comment", "Delete" };

        new AlertDialog.Builder(this)
                .setTitle(file.getName())
                .setItems(choices, new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        if (which == 0) {
                            showImage(file);
                        } else if (which == 1) {
                            editComment(file);
                        } else if (which == 2) {
                            confirmDelete(file);
                        }
                    }
                })
                .show();
    }

    private void showImage(File file) {
        Intent intent = new Intent(this, FullImageActivity.class);
        intent.putExtra("path", file.getAbsolutePath());
        startActivity(intent);
    }

    private void editComment(final File file) {
        final EditText edit = new EditText(this);
        edit.setMinLines(3);
        edit.setText(comments.getString(file.getAbsolutePath(), ""));

        new AlertDialog.Builder(this)
                .setTitle("Comment")
                .setView(edit)
                .setPositiveButton("Save", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        comments.edit()
                                .putString(file.getAbsolutePath(), edit.getText().toString())
                                .commit();
                        reloadList();
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void confirmDelete(final File file) {
        new AlertDialog.Builder(this)
                .setTitle("Delete image?")
                .setMessage(file.getAbsolutePath())
                .setPositiveButton("Delete", new DialogInterface.OnClickListener() {
                    @Override
                    public void onClick(DialogInterface dialog, int which) {
                        deleteImage(file);
                    }
                })
                .setNegativeButton("Cancel", null)
                .show();
    }

    private void deleteImage(File file) {
        String path = file.getAbsolutePath();
        if (file.exists()) {
            file.delete();
        }

        comments.edit().remove(path).commit();

        MediaScannerConnection.scanFile(
                this,
                new String[] { path },
                null,
                null
        );

        reloadList();
    }

    private int dp(int value) {
        return (int) (value * getResources().getDisplayMetrics().density + 0.5f);
    }
}
