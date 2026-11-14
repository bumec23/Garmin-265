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

    private var _isSleeping as Boolean = false;

    // false = saat lengan turun layar hitam (aman untuk AMOLED)
    // true  = tetap abu-abu penuh saat tidur (lebih boros, risiko burn-in)
    private var _grayWhenSleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onShow() as Void {}
    function onHide() as Void {}

    function onEnterSleep() as Void {
        _isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isSleeping = false;
        WatchUi.requestUpdate();
    }

    // Teks di dalam kotak berwarna. Saat tidur hanya garis kotak, teks putih.
    private function drawTextBox(dc as Dc, text as String, font,
                                 centerX as Number, centerY as Number,
                                 fillColor as Number, textColor as Number) as Void {
        var w = dc.getTextWidthInPixels(text, font) + 20;
        var h = dc.getFontHeight(font) + 6;
        var x = centerX - w / 2;
        var y = centerY - h / 2;

        var tc = textColor;
        if (_isSleeping) {
            tc = Graphics.COLOR_WHITE;
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
        dc.setColor(tc, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Satu angka 7-segment. d = 0..9. Segmen: a(atas) b(kanan atas) c(kanan bawah)
    // d(bawah) e(kiri bawah) f(kiri atas) g(tengah)
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

    // Jam digital bergaya 7-segment di dalam kotak.
    private function drawSegTime(dc as Dc, text as String,
                                 centerX as Number, centerY as Number,
                                 fillColor as Number, digitColor as Number) as Void {
        var dw = 14;
        var dh = 25;
        var t = 3;
        var gap = 4;
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

        var segColor = digitColor;
        if (_isSleeping) {
            segColor = Graphics.COLOR_WHITE;
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

        dc.setColor(segColor, Graphics.COLOR_TRANSPARENT);
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

    // Teks biasa (tanpa kotak), rata tengah.
    private function drawPlainText(dc as Dc, text as String, font,
                                   centerX as Number, centerY as Number,
                                   color as Number) as Void {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(centerX, centerY, font, text,
                    Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Ikon hati (digambar dari bentuk, pink) + angka detak jantung.
    private function drawHeartRate(dc as Dc, hrText as String, font,
                                   centerX as Number, centerY as Number,
                                   numColor as Number) as Void {
        var fh = dc.getFontHeight(font);
        var s = ((fh * 8) / 10 / 4) * 4;
        var rr = s / 4;
        var gap = 6;
        var tw = dc.getTextWidthInPixels(hrText, font);

        var startX = centerX - (s + gap + tw) / 2;
        var hx = startX + s / 2;
        var top = centerY - s / 4;

        dc.setColor(0xFF1493, Graphics.COLOR_TRANSPARENT);   // pink
        dc.fillCircle(hx - rr, top, rr);
        dc.fillCircle(hx + rr, top, rr);
        dc.fillPolygon([[hx - 2 * rr, top],
                        [hx + 2 * rr, top],
                        [hx, centerY + (s * 3) / 7]]);

        dc.setColor(numColor, Graphics.COLOR_TRANSPARENT);
        dc.drawText(startX + s + gap, centerY, font, hrText,
                    Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
    }

    // Jarum berujung anak panah. Sudut dalam derajat, 0 = jam 12.
    private function drawArrowHand(dc as Dc, cx as Number, cy as Number,
                                   angleDeg as Float, length as Number,
                                   tail as Number, shaftW as Number,
                                   headLen as Number, headW as Number) as Void {
        var a = angleDeg * Math.PI / 180.0;
        var s = Math.sin(a);
        var c = Math.cos(a);

        // poros jarum
        var bx = cx + (length - headLen) * s;
        var by = cy - (length - headLen) * c;
        dc.setPenWidth(shaftW);
        dc.drawLine(cx - tail * s, cy + tail * c, bx, by);

        // kepala anak panah (segitiga)
        dc.fillPolygon([[cx + length * s, cy - length * c],
                        [bx + headW * c, by + headW * s],
                        [bx - headW * c, by - headW * s]]);
    }

    // Tanda setiap menit seperti jam dinding (60 garis, tiap 5 menit lebih panjang).
    // Saat tidur hanya 12 tanda jam.
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
            dc.drawLine(cx + inner * s, cy - inner * c,
                        cx + outer * s, cy - outer * c);
        }
    }

    // Angka 1-12. Saat tidur hanya 12, 3, 6, 9.
    private function drawNumbers(dc as Dc, cx as Number, cy as Number,
                                 r as Number, font, color as Number) as Void {
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
            dc.drawText(x, y, font, i.format("%d"),
                        Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER);
        }
    }

    function onUpdate(dc as Dc) as Void {

        var w = dc.getWidth();
        var h = dc.getHeight();
        var cx = w / 2;
        var cy = h / 2;
        var r = cx;

        // Satu font untuk semua teks biasa (jam digital memakai gaya 7-segment).
        var uiFont = Graphics.FONT_SMALL;

        // 0. LATAR: SELURUH LAYAR LIGHT GRAY (hitam saat tidur)
        var bgColor = Graphics.COLOR_LT_GRAY;
        if (_isSleeping && !_grayWhenSleeping) {
            bgColor = Graphics.COLOR_BLACK;
        }
        var darkBg = (bgColor == Graphics.COLOR_BLACK);
        // warna "tinta": putih di latar hitam, hitam di latar terang
        var inkColor = darkBg ? Graphics.COLOR_WHITE : Graphics.COLOR_BLACK;

        dc.setColor(Graphics.COLOR_WHITE, bgColor);
        dc.clear();

        if (dc has :setAntiAlias) {
            dc.setAntiAlias(true);
        }

        // 1. WAKTU DIGITAL
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
            timeString = useMilitary ? (hh + mm) : (hh + ":" + mm);
        } else {
            timeString = useMilitary ? (hh + mm + ":" + ss) : (hh + ":" + mm + ":" + ss);
        }

        // 2. TANGGAL (format: 15 NOV)
        var months = ["JAN", "FEB", "MAR", "APR", "MAY", "JUN",
                      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"];
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = dateInfo.day.format("%02d") + " " + months[dateInfo.month - 1];

        // 3. BATERAI (warna lebih gelap di latar terang agar terbaca)
        var batt = System.getSystemStats().battery.toNumber();
        var battColor;
        if (batt <= 20) {
            battColor = darkBg ? Graphics.COLOR_RED : Graphics.COLOR_DK_RED;
        } else {
            battColor = darkBg ? Graphics.COLOR_GREEN : Graphics.COLOR_DK_GREEN;
        }

        // 4. DETAK JANTUNG
        var hrString = "--";
        try {
            var actInfo = Activity.getActivityInfo();
            if (actInfo != null && actInfo.currentHeartRate != null) {
                hrString = actInfo.currentHeartRate.format("%d");
            } else {
                var hist = ActivityMonitor.getHeartRateHistory(1, true);
                var sample = hist.next();
                if (sample != null && sample.heartRate != ActivityMonitor.INVALID_HR_SAMPLE) {
                    hrString = sample.heartRate.format("%d");
                }
            }
        } catch (ex) {
            hrString = "--";
        }

        // 5. GAMBAR TEKS
        drawHeartRate(dc, hrString, uiFont, (w * 30) / 100, cy, inkColor);

        drawTextBox(dc, dateString, uiFont, (w * 70) / 100, cy,
                    Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        drawPlainText(dc, batt.format("%d") + "%", uiFont, cx, (h * 62) / 100, battColor);

        drawSegTime(dc, timeString, cx, (h * 76) / 100,
                    Graphics.COLOR_WHITE, Graphics.COLOR_BLACK);

        // 6. TANDA MENIT, ANGKA, DAN JARUM ANALOG
        drawMinuteTicks(dc, cx, cy, r, inkColor);
        drawNumbers(dc, cx, cy, r, uiFont, inkColor);

        var hourAngle = ((clockTime.hour % 12) + clockTime.min / 60.0) * 30.0;
        var minAngle = (clockTime.min + clockTime.sec / 60.0) * 6.0;
        var secAngle = clockTime.sec * 6.0;

        // jarum jam dan menit (anak panah)
        dc.setColor(inkColor, Graphics.COLOR_TRANSPARENT);
        drawArrowHand(dc, cx, cy, hourAngle, (r * 50) / 100, 12, 6, 18, 8);
        drawArrowHand(dc, cx, cy, minAngle, (r * 76) / 100, 12, 4, 20, 7);

        // jarum detik (anak panah, hanya saat layar menyala penuh)
        if (!_isSleeping) {
            dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_TRANSPARENT);
            drawArrowHand(dc, cx, cy, secAngle, (r * 88) / 100, 24, 2, 14, 5);
        }

        // titik tengah
        dc.setColor(Graphics.COLOR_BLACK, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 7);
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        dc.drawCircle(cx, cy, 7);
    }
}
