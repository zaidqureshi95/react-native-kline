package com.byron.kline.render;

import android.content.Context;
import android.graphics.Canvas;
import android.graphics.Paint;

import androidx.annotation.NonNull;

import com.byron.kline.R;
import com.byron.kline.base.BaseKChartView;
import com.byron.kline.base.BaseRender;
import com.byron.kline.formatter.IValueFormatter;
import com.byron.kline.formatter.ValueFormatter;
import com.byron.kline.utils.Constants;
import com.byron.kline.utils.NumberTools;
import com.byron.kline.utils.Status;

import java.util.Arrays;

/*************************************************************************
 * Description   :
 *
 * @PackageName  : com.byron.kline.utils
 * @FileName     : VolumeDraw.java
 * @Author       : chao
 * @Date         : 2019/4/8
 * @Email        : icechliu@gmail.com
 * @version      : V1
 *************************************************************************/
public class VolumeRender extends BaseRender {

    private Paint linePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Paint increasePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Paint decreasePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Paint maOnePaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Paint maTwoPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private Paint volLeftPaint = new Paint(Paint.ANTI_ALIAS_FLAG);
    private float volWidth, lineVolWidth, volLegendMarginTop, endMaOne, endMaTwo;
    private IValueFormatter valueFormatter = new ValueFormatter();
    private int itemsCount;
    private final int indexInterval;
    private String volMaIndex1, volMaIndex2, volIndex;

    public VolumeRender(Context context) {
        indexInterval = Constants.getCount();
        volIndex = context.getString(R.string.k_index_vol);
        String temp = context.getString(R.string.k_index_vol_ma);
        volMaIndex1 = String.format(temp, Constants.K_VOL_MA_NUMBER_1);
        volMaIndex2 = String.format(temp, Constants.K_VOL_MA_NUMBER_2);
    }


    @Override
    public void render(Canvas canvas, float lastX, float curX, @NonNull BaseKChartView view, int position, float... values) {
        if (position == 0) {
            drawHistogram(canvas, curX,
                    values[Constants.INDEX_VOL],
                    values[Constants.INDEX_OPEN],
                    values[Constants.INDEX_CLOSE]
                    , view, position);
        } else {
            drawHistogram(canvas, curX,
                    values[Constants.INDEX_VOL + indexInterval],
                    values[Constants.INDEX_OPEN + indexInterval],
                    values[Constants.INDEX_CLOSE + indexInterval]
                    , view, position);
            drawLine(lastX, curX, canvas, view, position,
                    values[Constants.INDEX_VOL_MA_1],
                    endMaOne, maOnePaint,
                    values[Constants.INDEX_VOL_MA_1 + indexInterval]);
            drawLine(lastX, curX, canvas, view, position,
                    values[Constants.INDEX_VOL_MA_2],
                    endMaTwo, maTwoPaint,
                    values[Constants.INDEX_VOL_MA_2 + indexInterval]);
        }

    }

    private void drawLine(float lastX, float curX, @NonNull Canvas canvas, @NonNull BaseKChartView view, int position, float lastMa, float endMa5, Paint ma5Paint, float currentMa) {
        if (Float.MIN_VALUE != lastMa) {
            if (position == itemsCount - 1 && 0 != endMa5 && view.isAnimationLast()) {
                view.renderVolLine(canvas, ma5Paint, lastX, lastMa, curX, endMa5);
            } else {
                view.renderVolLine(canvas, ma5Paint, lastX, lastMa, curX, currentMa);
            }
        }
    }

 private void drawHistogram(Canvas canvas, float curX, float vol, float open, float close, BaseKChartView view, int position) {

    // Adjust bar width based on zoom level (scale factor)
    float zoomFactor = view.getScaleX(); // This represents the zoom level of the chart
    float dynamicWidth = Math.max(5.0f, 10.0f * zoomFactor); // Define a base width and scale it by the zoom level
    float top, r = volWidth / 2 * zoomFactor;  // Adjust the radius based on zoom level
    int bottom = view.getVolRectBottom();
    
    if (position == itemsCount - 1 && view.isAnimationLast()) {
        top = view.getVolY(view.getLastVol());
    } else {
        top = view.getVolY(vol);
    }
    
    if (0 != vol && top > bottom - 2) {
        top = bottom - 2;
    }

   if ((null == view.getVolChartStatus() && view.getKlineStatus().showLine()) || 
    view.getVolChartStatus() == Status.VolChartStatus.LINE_CHART) {
    // For line chart, use increase or decrease paint based on the price movement
    if (close >= open) {
        canvas.drawRect(curX - r, top, curX + r, bottom, increasePaint);
    } else {
        canvas.drawRect(curX - r, top, curX + r, bottom, decreasePaint);
    }
} else if (close >= open) {
    canvas.drawRect(curX - r, top, curX + r, bottom, increasePaint);
} else {
    canvas.drawRect(curX - r, top, curX + r, bottom, decreasePaint);
}
}


    @Override
    public void renderText(@NonNull Canvas canvas, @NonNull BaseKChartView view, float x, float y, int position, float[] values) {
        String text;
        volLegendMarginTop += volLegendMarginTop;
        if (position == itemsCount - 1 && view.isAnimationLast()) {
            text = volIndex + NumberTools.formatAmount(getValueFormatter().format(view.getLastVol())) + "  ";
        } else {
            text = volIndex + NumberTools.formatAmount(getValueFormatter().format(values[Constants.INDEX_VOL])) + "  ";
        }
        canvas.drawText(text, x, y, volLeftPaint);
        x += view.getCommonTextPaint().measureText(text);

        if (position == itemsCount - 1 && view.isAnimationLast() && 0 != endMaOne) {
            text = volMaIndex1 + NumberTools.formatAmount(getValueFormatter().format(endMaOne)) + "  ";
        } else {
            text = volMaIndex1 + NumberTools.formatAmount(getValueFormatter().format(values[Constants.INDEX_VOL_MA_1])) + "  ";
        }
        canvas.drawText(text, x, y, maOnePaint);
        x += maOnePaint.measureText(text);
        if (position == itemsCount - 1 && view.isAnimationLast() && 0 != endMaOne) {

            text = volMaIndex2 + NumberTools.formatAmount(getValueFormatter().format(endMaTwo)) + "  ";
        } else {
            text = volMaIndex2 + NumberTools.formatAmount(getValueFormatter().format(values[Constants.INDEX_VOL_MA_2])) + "  ";
        }
        canvas.drawText(text, x, y, maTwoPaint);
    }

    @Override
    public IValueFormatter getValueFormatter() {
        return valueFormatter;
    }

    @Override
    public void setValueFormatter(IValueFormatter valueFormatter) {
        this.valueFormatter = valueFormatter;
    }

    @Override
    public void setItemCount(int mItemCount) {
        this.itemsCount = mItemCount;
    }

    @Override
    public void startAnim(BaseKChartView view, float... values) {
        if (0 == endMaOne) {
            endMaOne = values[Constants.INDEX_VOL_MA_1];
            endMaTwo = values[Constants.INDEX_VOL_MA_2];
        } else {
            view.generaterAnimator(endMaOne, values[Constants.INDEX_VOL_MA_1], animation -> endMaOne = (float) animation.getAnimatedValue());
            view.generaterAnimator(endMaTwo, values[Constants.INDEX_VOL_MA_2], animation -> endMaTwo = (float) animation.getAnimatedValue());
        }
    }

    /**
     * 设置 MA5 线的颜色
     *
     * @param color
     */
    public void setMaOneColor(int color) {
        this.maOnePaint.setColor(color);
    }

    /**
     * 设置 vol图左上角文字 线的颜色
     *
     * @param color
     */
    public void setVolLegendColor(int color) {
        this.volLeftPaint.setColor(color);
    }


    /**
     * 设置 MA10 线的颜色
     *
     * @param color
     */
    public void setMaTwoColor(int color) {
        this.maTwoPaint.setColor(color);
    }


    public void setLineWidth(float width) {
        this.linePaint.setStrokeWidth(width);
        this.maOnePaint.setStrokeWidth(width);
        this.maTwoPaint.setStrokeWidth(width);
        this.lineVolWidth = width / 2;
    }

    /**
     * 设置文字大小
     *
     * @param textSize textSize
     */
    public void setTextSize(float textSize) {
        this.maOnePaint.setTextSize(textSize);
        this.maTwoPaint.setTextSize(textSize);
        this.volLeftPaint.setTextSize(textSize);
    }

    public void setBarWidth(float candleWidth) {
        volWidth = candleWidth;
    }


    @Override
    public void resetValues() {
        endMaOne = 0;
        endMaTwo = 0;
    }

    public void setLineChartColor(int color) {
        linePaint.setColor(color);
    }

    public void setVolLegendMarginTop(float volLegendMarginTop) {
        this.volLegendMarginTop = volLegendMarginTop;
    }

    public void setIncreaseColor(int color) {
        this.increasePaint.setColor(color);
    }

    public void setDecreaseColor(int color) {
        this.decreasePaint.setColor(color);
    }

    public float getMinValue(float... values) {
        int length = values.length;
        if (length == 0) {
            return 0;
        }
        Arrays.sort(values);
        for (int i = 0; i < length; i++) {
            if (values[i] >= 0) {
                return values[i];
            }
        }
        return 0;
    }
}
