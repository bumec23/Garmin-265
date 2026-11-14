
import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class Minimal265View extends WatchUi.WatchFace {

    private var _companyLogo;
    private var _showLogoWhenSleeping = false;

    private var _isSleeping as Boolean = false;
    private var _grayWhenSleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onShow() as Void {
    _companyLogo = WatchUi.loadResource(
        Rez.Drawables.CompanyLogo
    );
    }
    
    function onHide() as Void {}

    function onEnterSleep() as Void {
        _isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isSleeping = false;
        WatchUi.requestUpdate();
    }

    // ============================================================
    // DATE BOX
    // ============================================================

    private function drawTextBox(dc as Dc, text as String, font,
                                 centerX as Number, centerY as Number,
                                 fillColor as Number, textColor as Number) as Void {

        var w = dc.getTextWidthInPixels(text, font) + 20;
        var h = dc.getFontHeight(font) + 6;
        var x = centerX - w / 2;
        var y = centerY - h / 2;

        if (_isSleeping) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawRoundedRectangle(x, y, w, h, 8);
        } else {
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(x, y, w, h, 8);

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawRoundedRectangle(x, y, w, h, 8);
        }

        dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER |
                    Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ============================================================
    // 7 SEGMENT DIGIT
    // ============================================================

    private function drawDigit(dc as Dc, x as Number, y as Number,
                               w as Number, h as Number, t as Number,
                               d as Number) as Void {

        var segs = [63, 6, 91, 79, 102, 109, 125, 7, 127, 111];
        var m = segs[d];

        var hs = w - 2 * t;
        var vs = (h - 3 * t) / 2;
        var gy = (h - t) / 2;

        if ((m & 1) != 0)  { dc.fillRectangle(x + t, y, hs, t); }
        if ((m & 2) != 0)  { dc.fillRectangle(x + w - t, y + t, t, vs); }
        if ((m & 4) != 0)  { dc.fillRectangle(x + w - t, y + gy + t, t, vs); }
        if ((m & 8) != 0)  { dc.fillRectangle(x + t, y + h - t, hs, t); }
        if ((m & 16) != 0) { dc.fillRectangle(x, y + gy + t, t, vs); }
        if ((m & 32) != 0) { dc.fillRectangle(x, y + t, t, vs); }
        if ((m & 64) != 0) { dc.fillRectangle(x + t, y + gy, hs, t); }
    }

    // ============================================================
    // DIGITAL CLOCK
    // ============================================================

    private function drawSegTime(dc as Dc, text as String,
                                 centerX as Number, centerY as Number,
                                 fillColor as Number, digitColor as Number,
                                 dw as Number, dh as Number,
                                 t as Number, gap as Number) as Void {

        var colonW = 5;
        var chars = text.toCharArray();
        var n = chars.size();

        var total = 0;

        for (var i = 0; i < n; i++) {
            var code = chars[i].toNumber();
            total += (code == 58) ? colonW : dw;

            if (i < n - 1) {
                total += gap;
            }
        }

        var boxW = total + 24;
        var boxH = dh + 14;
        var boxX = centerX - boxW / 2;
        var boxY = centerY - boxH / 2;

        if (_isSleeping) {
            dc.setColor(Graphics.COLOR_LT_GRAY, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawRoundedRectangle(boxX, boxY, boxW, boxH, 8);
        } else {
            dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);
            dc.fillRoundedRectangle(boxX, boxY, boxW, boxH, 8);

            dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawRoundedRectangle(boxX, boxY, boxW, boxH, 8);
        }

        dc.setColor(digitColor, Graphics.COLOR_TRANSPARENT);

        var x = centerX - total / 2;
        var y = centerY - dh / 2;

        for (var i = 0; i < n; i++) {
            var code = chars[i].toNumber();

            if (code == 58) {
                var cxp = x + (colonW - t) / 2;

                dc.fillRectangle(cxp, y + dh / 3 - t / 2, t, t);
                dc.fillRectangle(cxp, y + (dh * 2) / 3 - t / 2, t, t);

                x += colonW + gap;

            } else {
                var digit = code - 48;

                if (digit >= 0 && digit <= 9) {
                    drawDigit(dc, x, y, dw, dh, t, digit);
                }

                x += dw + gap;
            }
        }
    }

    // ============================================================
    // HEART RATE
    // ============================================================

    private function drawHeartRate(dc as Dc, hrText as String, font,
                                   centerX as Number, centerY as Number,
                                   numColor as Number,
                                   iconColor as Number) as Void {

        var fh = dc.getFontHeight(font);
        var s = ((fh * 8) / 10 / 4) * 4;
        var rr = s / 4;
        var gap = 6;

        var tw = dc.getTextWidthInPixels(hrText, font);

        var startX = centerX - (s + gap + tw) / 2;
        var hx = startX + s / 2;
        var top = centerY - s / 4;

        dc.setColor(iconColor, Graphics.COLOR_TRANSPARENT);

        dc.fillCircle(hx - rr, top, rr);
        dc.fillCircle(hx + rr, top, rr);

        dc.fillPolygon([
            [hx - 2 * rr, top],
            [hx + 2 * rr, top],
            [hx, centerY + (s * 3) / 7]
        ]);

        dc.setColor(numColor, Graphics.COLOR_TRANSPARENT);

        dc.drawText(startX + s + gap, centerY, font, hrText,
                    Graphics.TEXT_JUSTIFY_LEFT |
                    Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // ============================================================
    // SMARTPHONE BATTERY INDICATOR
    // ============================================================

    private function drawBattery(dc as Dc, value as Number, font,
                             centerX as Number, centerY as Number,
                             fillColor as Number,
                             emptyColor as Number,
                             outlineColor as Number,
                             textColor as Number) as Void {

    var batt = value;

    if (batt < 0) {
        batt = 0;
    }

    if (batt > 100) {
        batt = 100;
    }

    // BATTERY GRAPHIC
    var bodyW = 52;
    var bodyH = 23;

    var terminalW = 4;
    var terminalH = 9;

    // Grafik berada di sebelah kiri
    var x = centerX - 35;
    var y = centerY - bodyH / 2;

    var innerX = x + 3;
    var innerY = y + 3;

    var innerW = bodyW - 6;
    var innerH = bodyH - 6;

    // Battery empty area
    dc.setColor(emptyColor, Graphics.COLOR_TRANSPARENT);

    dc.fillRoundedRectangle(
        innerX, innerY, innerW, innerH, 3
    );

    // Battery level
    var fillW = (innerW * batt) / 100;

    if (fillW > 0) {
        dc.setColor(fillColor, Graphics.COLOR_TRANSPARENT);

        dc.fillRoundedRectangle(
            innerX, innerY, fillW, innerH, 3
        );
    }

    // Battery outline
    dc.setColor(outlineColor, Graphics.COLOR_TRANSPARENT);
    dc.setPenWidth(2);

    dc.drawRoundedRectangle(
        x, y, bodyW, bodyH, 4
    );

    // Battery terminal
    dc.fillRoundedRectangle(
        x + bodyW,
        centerY - terminalH / 2,
        terminalW,
        terminalH,
        2
    );

    // Percentage on right side
    dc.setColor(textColor, Graphics.COLOR_TRANSPARENT);

    dc.drawText(
        x + bodyW + terminalW + 7,
        centerY,
        font,
        batt.format("%d") + "%",
        Graphics.TEXT_JUSTIFY_LEFT |
        Graphics.TEXT_JUSTIFY_VCENTER
    );
    }

    // ============================================================
    // ANALOG CLOCK HANDS
    // ============================================================

    private function drawArrowHand(dc as Dc, cx as Number, cy as Number,
                                   angleDeg as Float, length as Number,
                                   tail as Number, shaftW as Number,
                                   headLen as Number,
                                   headW as Number) as Void {

        var a = angleDeg * Math.PI / 180.0;
        var s = Math.sin(a);
        var c = Math.cos(a);

        var bx = cx + (length - headLen) * s;
        var by = cy - (length - headLen) * c;

        dc.setPenWidth(shaftW);

        dc.drawLine(
            cx - tail * s,
            cy + tail * c,
            bx,
            by
        );

        dc.fillPolygon([
            [cx + length * s, cy - length * c],
            [bx + headW * c, by + headW * s],
            [bx - headW * c, by - headW * s]
        ]);
    }

    // ============================================================
    // MINUTE TICKS
    // ============================================================

    private function drawMinuteTicks(dc as Dc, cx as Number, cy as Number,
                                     r as Number, color as Number) as Void {

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        for (var i = 0; i < 60; i++) {

            var isHour = (i % 5 == 0);

            if (_isSleeping && !isHour) {
                continue;
            }

            var a = i * 6.0 * Math.PI / 180.0;

            var s = Math.sin(a);
            var c = Math.cos(a);

            var outer = r - 2;
            var inner = isHour ? (r - 16) : (r - 9);

            dc.setPenWidth(isHour ? 3 : 1);

            dc.drawLine(
                cx + inner * s,
                cy - inner * c,
                cx + outer * s,
                cy - outer * c
            );
        }
    }

    // ============================================================
    // ANALOG NUMBERS
    // ============================================================

    private function drawNumbers(dc as Dc, cx as Number, cy as Number,
                                 r as Number, font,
                                 color as Number) as Void {

        dc.setColor(color, Graphics.COLOR_TRANSPARENT);

        for (var i = 1; i <= 12; i++) {

            var major = (i % 3 == 0);

            if (_isSleeping && !major) {
                continue;
            }

            var a = i * 30.0 * Math.PI / 180.0;

            var nr = r - 36;

            var x = cx + nr * Math.sin(a);
            var y = cy - nr * Math.cos(a);

            dc.drawText(
                x,
                y,
                font,
                i.format("%d"),
                Graphics.TEXT_JUSTIFY_CENTER |
                Graphics.TEXT_JUSTIFY_VCENTER
            );
        }
    }

private function drawCompanyLogo(dc as Dc,
                                 centerX as Number,
                                 centerY as Number) as Void {

    if (_companyLogo == null) {
        return;
    }

    dc.drawBitmap(
        centerX - 32,
        centerY - 30,
        _companyLogo
    );
}

    // ============================================================
    // MAIN DISPLAY
    // ============================================================

    function onUpdate(dc as Dc) as Void {

        var w = dc.getWidth();
        var h = dc.getHeight();

        var cx = w / 2;
        var cy = h / 2;
        var r = cx;

        // ========================================================
        // 1. FONT SETTINGS - INDEPENDENT GROUPS
        // ========================================================

        var heartRateFont = Graphics.FONT_TINY;
        var dateFont = Graphics.FONT_XTINY;
        var batteryFont = Graphics.FONT_XTINY;
        var analogNumberFont = Graphics.FONT_MEDIUM;

        // DIGITAL CLOCK SIZE
        var timeDigitWidth = 14;
        var timeDigitHeight = 25;
        var timeSegmentThickness = 3;
        var timeDigitGap = 4;

        // ========================================================
        // 2. BACKGROUND
        // ========================================================

        var bgColor = Graphics.COLOR_LT_GRAY;

        if (_isSleeping && !_grayWhenSleeping) {
            bgColor = Graphics.COLOR_BLACK;
        }

        var darkBg = (bgColor == Graphics.COLOR_BLACK);

        var inkColor = darkBg ?
                       Graphics.COLOR_WHITE :
                       Graphics.COLOR_BLACK;

        // ========================================================
        // 3. INDEPENDENT COLOR SETTINGS
        // ========================================================

        // HEART RATE
        var heartRateNumberColor = inkColor;
        var heartIconColor = 0xFF1493;

        // DATE
        var dateFillColor = Graphics.COLOR_WHITE;
        var dateTextColor = inkColor;

        // DIGITAL CLOCK
        var timeBoxFillColor = Graphics.COLOR_WHITE;
        var timeDigitColor = Graphics.COLOR_BLACK;

        // BATTERY
        var batteryFillColor = Graphics.COLOR_GREEN;
        var batteryEmptyColor = Graphics.COLOR_DK_GRAY;
        var batteryOutlineColor = inkColor;
        var batteryTextColor = Graphics.COLOR_BLACK;

        // ANALOG CLOCK
        var analogTickColor = inkColor;
        var analogNumberColor = inkColor;

        var hourHandColor = inkColor;
        var minuteHandColor = inkColor;
        var secondHandColor = Graphics.COLOR_RED;

        var centerPinColor = darkBg ?
                             Graphics.COLOR_WHITE :
                             Graphics.COLOR_BLACK;

        var centerPinOutlineColor = darkBg ?
                                    Graphics.COLOR_BLACK :
                                    Graphics.COLOR_WHITE;

        // ========================================================
        // 4. CLEAR DISPLAY
        // ========================================================

        dc.setColor(Graphics.COLOR_WHITE, bgColor);
        dc.clear();

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        // ========================================================
        // 5. TIME DATA
        // ========================================================

        var clockTime = System.getClockTime();

        var hours = clockTime.hour;

        var is24 = System.getDeviceSettings().is24Hour;

        var useMilitary = false;

        if (is24) {

            try {
                var prop = Application.Properties.getValue("UseMilitaryFormat");

                useMilitary = (prop != null && prop == true);

            } catch (ex) {
                useMilitary = false;
            }

        } else {

            hours = hours % 12;

            if (hours == 0) {
                hours = 12;
            }
        }

        var hh = hours.format(is24 ? "%02d" : "%d");
        var mm = clockTime.min.format("%02d");
        var ss = clockTime.sec.format("%02d");

        var timeString;

        if (_isSleeping) {

            timeString = useMilitary ?
                         (hh + mm) :
                         (hh + ":" + mm);

        } else {

            timeString = useMilitary ?
                         (hh + mm + ":" + ss) :
                         (hh + ":" + mm + ":" + ss);
        }

        // ========================================================
        // 6. DATE DATA
        // ========================================================

        var months = [
            "JAN", "FEB", "MAR", "APR",
            "MAY", "JUN", "JUL", "AUG",
            "SEP", "OCT", "NOV", "DEC"
        ];

        var dateInfo = Gregorian.info(
            Time.now(),
            Time.FORMAT_SHORT
        );

        var dateString =
            dateInfo.day.format("%02d") + " " +
            months[dateInfo.month - 1];

        // ========================================================
        // 7. BATTERY DATA
        // ========================================================

        var batt = System.getSystemStats().battery.toNumber();

        if (batt <= 20) {
            batteryFillColor = Graphics.COLOR_RED;
        } else {
            batteryFillColor = Graphics.COLOR_GREEN;
        }

        // ========================================================
        // 8. HEART RATE DATA
        // ========================================================

        var hrString = "--";

        try {

            var actInfo = Activity.getActivityInfo();

            if (actInfo != null &&
                actInfo.currentHeartRate != null) {

                hrString = actInfo.currentHeartRate.format("%d");

            } else {

                var hist = ActivityMonitor.getHeartRateHistory(1, true);
                var sample = hist.next();

                if (sample != null &&
                    sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {

                    hrString = sample.heartRate.format("%d");
                }
            }

        } catch (ex) {
            hrString = "--";
        }

        // ========================================================
        // 9. DRAW HEART RATE
        // ========================================================

        drawHeartRate(
            dc,
            hrString,
            heartRateFont,
            (w * 30) / 100,
            cy,
            heartRateNumberColor,
            heartIconColor
        );

        // ========================================================
        // 10. DRAW DATE
        // ========================================================

        drawTextBox(
            dc,
            dateString,
            dateFont,
            (w * 70) / 100,
            cy,
            dateFillColor,
            dateTextColor
        );

        // ========================================================
        // 11. DRAW SMARTPHONE BATTERY
        // ========================================================

        drawBattery(
            dc,
            batt,
            batteryFont,
            cx,
            (h * 30) / 100,
            batteryFillColor,
            batteryEmptyColor,
            batteryOutlineColor,
            batteryTextColor
        );

        // ========================================================
        // 12. DRAW DIGITAL CLOCK
        // ========================================================

        drawSegTime(
            dc,
            timeString,
            cx,
            (h * 76) / 100,
            timeBoxFillColor,
            timeDigitColor,
            timeDigitWidth,
            timeDigitHeight,
            timeSegmentThickness,
            timeDigitGap
        );

        // LOGO INOTECH
        if (!_isSleeping || _showLogoWhenSleeping) {
        drawCompanyLogo(
        dc,
        cx,
        (h * 63) / 100
        );
        }

        // ========================================================
        // 13. DRAW ANALOG CLOCK
        // ========================================================

        drawMinuteTicks(
            dc,
            cx,
            cy,
            r,
            analogTickColor
        );

        drawNumbers(
            dc,
            cx,
            cy,
            r,
            analogNumberFont,
            analogNumberColor
        );

        var hourAngle =
            ((clockTime.hour % 12) + clockTime.min / 60.0) * 30.0;

        var minAngle =
            (clockTime.min + clockTime.sec / 60.0) * 6.0;

        var secAngle = clockTime.sec * 6.0;

        // HOUR HAND
        dc.setColor(hourHandColor, Graphics.COLOR_TRANSPARENT);

        drawArrowHand(
            dc,
            cx,
            cy,
            hourAngle,
            (r * 50) / 100,
            12,
            6,
            18,
            8
        );

        // MINUTE HAND
        dc.setColor(minuteHandColor, Graphics.COLOR_TRANSPARENT);

        drawArrowHand(
            dc,
            cx,
            cy,
            minAngle,
            (r * 76) / 100,
            12,
            4,
            20,
            7
        );

        // SECOND HAND
        if (!_isSleeping) {

            dc.setColor(secondHandColor, Graphics.COLOR_TRANSPARENT);

            drawArrowHand(
                dc,
                cx,
                cy,
                secAngle,
                (r * 95) / 100,
                24,
                2,
                14,
                5
            );
        }

        // ========================================================
        // 14. CENTER PIN
        // ========================================================

        dc.setColor(centerPinColor, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 7);

        dc.setColor(centerPinOutlineColor, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, 7);
            
    }
}
