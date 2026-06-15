package org.foodsnap;

import android.content.Context;
import android.graphics.Bitmap;
import android.graphics.BitmapFactory;
import android.os.Environment;

import java.io.File;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Locale;

public class ImageFiles {
    public static File getFoodSnapRoot(Context context) {
        FoodSnapPrefs prefs = new FoodSnapPrefs(context);
        File pictures = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_PICTURES);
        return new File(pictures, prefs.getSaveFolderName());
    }

    public static File getDayFolder(Context context, long millis) {
        FoodSnapPrefs prefs = new FoodSnapPrefs(context);
        return new File(getFoodSnapRoot(context), prefs.formatDayFolder(millis));
    }

    public static ArrayList<File> listImagesNewestFirst(Context context) {
        ArrayList<File> files = new ArrayList<File>();
        File root = getFoodSnapRoot(context);
        collectImages(root, files);

        Collections.sort(files, new Comparator<File>() {
            @Override
            public int compare(File a, File b) {
                long diff = b.lastModified() - a.lastModified();
                if (diff < 0) {
                    return -1;
                }
                if (diff > 0) {
                    return 1;
                }
                return b.getAbsolutePath().compareTo(a.getAbsolutePath());
            }
        });

        return files;
    }

    public static File latestImage(Context context) {
        ArrayList<File> files = listImagesNewestFirst(context);
        if (files.size() == 0) {
            return null;
        }
        return files.get(0);
    }

    private static void collectImages(File dir, ArrayList<File> out) {
        if (dir == null || !dir.exists() || !dir.isDirectory()) {
            return;
        }

        File[] kids = dir.listFiles();
        if (kids == null) {
            return;
        }

        for (int i = 0; i < kids.length; i++) {
            File f = kids[i];
            if (f.isDirectory()) {
                collectImages(f, out);
            } else if (isImageFile(f)) {
                out.add(f);
            }
        }
    }

    public static boolean isImageFile(File f) {
        String name = f.getName().toLowerCase(Locale.US);
        return name.endsWith(".jpg") || name.endsWith(".jpeg") || name.endsWith(".png");
    }

    public static Bitmap decodeSampledBitmap(String path, int reqWidth, int reqHeight) {
        if (path == null) {
            return null;
        }

        BitmapFactory.Options bounds = new BitmapFactory.Options();
        bounds.inJustDecodeBounds = true;
        BitmapFactory.decodeFile(path, bounds);

        BitmapFactory.Options opts = new BitmapFactory.Options();
        opts.inSampleSize = calculateInSampleSize(bounds, reqWidth, reqHeight);

        try {
            return BitmapFactory.decodeFile(path, opts);
        } catch (OutOfMemoryError oom) {
            opts.inSampleSize = opts.inSampleSize * 2;
            try {
                return BitmapFactory.decodeFile(path, opts);
            } catch (OutOfMemoryError ignored) {
                return null;
            }
        }
    }

    private static int calculateInSampleSize(BitmapFactory.Options options,
                                             int reqWidth,
                                             int reqHeight) {
        int height = options.outHeight;
        int width = options.outWidth;
        int inSampleSize = 1;

        if (reqWidth <= 0) {
            reqWidth = 800;
        }
        if (reqHeight <= 0) {
            reqHeight = 800;
        }

        if (height > reqHeight || width > reqWidth) {
            int halfHeight = height / 2;
            int halfWidth = width / 2;

            while ((halfHeight / inSampleSize) >= reqHeight
                    && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2;
            }
        }

        if (inSampleSize < 1) {
            inSampleSize = 1;
        }

        return inSampleSize;
    }
}
