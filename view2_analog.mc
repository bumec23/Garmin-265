import Toybox.Activity;
import Toybox.ActivityMonitor;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.Math;
import Toybox.SensorHistory;
import Toybox.System;
import Toybox.Time;
import Toybox.Time.Gregorian;
import Toybox.Weather;
import Toybox.WatchUi;

// ============================================================
//  TEMA WARNA - ubah semua warna di sini saja (format 0xRRGGBB)
// ============================================================
module Theme {
    // Dial & bezel
    const BG            = 0xFFFFFF;  // latar dial
    const RING          = 0xE6E6E6;  // cincin abu-abu di tepi
    const TICK          = 0xA0A0A0;  // garis menit biasa
    const ACCENT        = 0xFF6A00;  // oranye: tick bezel, jarum gauge, badge hari, body battery
    const ACCENT_TICKS  = [0, 5, 10, 15];  // posisi menit yang diberi warna aksen

    // Sub-dial hitam
    const DIAL_BG       = 0x000000;
    const DIAL_TEXT     = 0xFFFFFF;
    const DIAL_DIVIDER  = 0x555555;
    const DIAL_MUTED    = 0xAAAAAA;  // label E, F
    const BB_ICON_TEXT  = 0x000000;  // ikon + angka di lingkaran body battery

    // Panel kiri
    const PANEL         = 0xD9D9D9;  // baji abu-abu muda
    const STRIP         = 0xC4C4C4;  // strip kalori + jarak
    const TEXT_DARK     = 0x000000;
    const TEXT_MUTED    = 0x666666;
    const HEART         = 0x000000;  // ikon hati
    const SUN           = 0xFFB347;  // matahari ikon cuaca
    const CLOUD         = 0xB8B8B8;  // awan ikon cuaca

    // Kalender bawah
    const BADGE_DAY_BG  = 0xFF6A00;
    const BADGE_DAY_TXT = 0x000000;
    const BADGE_DATE_BG = 0xD0D0D0;
    const BADGE_DATE_TXT= 0x000000;

    // Jam digital
    const TIME_TEXT     = 0x000000;
    const SECONDS_TEXT  = 0x777777;

    // Jarum analog
    const HAND_FILL     = 0xFFFFFF;
    const HAND_EDGE     = 0x222222;
    const SECOND_HAND   = 0x000000;
}

// ============================================================
//  TEMA FONT - ubah ukuran font tiap elemen di sini
//  (kecil -> besar: XTINY, TINY, SMALL, MEDIUM, LARGE)
// ============================================================
module Fonts {
    const TIME        = Graphics.FONT_NUMBER_MILD;  // jam digital (NUMBER_MILD / MEDIUM / HOT)
    const AMPM        = Graphics.FONT_XTINY;
    const SECONDS     = Graphics.FONT_XTINY;
    const CALENDAR    = Graphics.FONT_XTINY;        // hari + tanggal
    const HEART_RATE  = Graphics.FONT_SMALL;
    const TEMP        = Graphics.FONT_SMALL;
    const LABEL       = Graphics.FONT_XTINY;        // "Bpm", "Temp.°C"
    const STRIP       = Graphics.FONT_TINY;         // kalori + jarak
    const DIAL_VALUE  = Graphics.FONT_TINY;         // angka di sub-dial, notifikasi, body battery, langkah
    const GAUGE_LABEL = Graphics.FONT_XTINY;        // 20/40/60/80, E, F
}

class Analog2View extends WatchUi.WatchFace {

    var w = 416;
    var h = 416;
    var cx = 208;
    var cy = 208;
    var sleeping = false;
    var C;   // center + vcenter
    var L;   // left + vcenter

    function initialize() {
        WatchFace.initialize();
        C = Graphics.TEXT_JUSTIFY_CENTER | Graphics.TEXT_JUSTIFY_VCENTER;
        L = Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER;
    }

    function onLayout(dc) {
        w = dc.getWidth();
        h = dc.getHeight();
        cx = w / 2;
        cy = h / 2;
    }

    function onEnterSleep() { sleeping = true;  WatchUi.requestUpdate(); }
    function onExitSleep()  { sleeping = false; WatchUi.requestUpdate(); }

    // ---------- helper posisi (dalam persen layar) ----------
    function px(p) { return (w * p / 100.0).toNumber(); }
    function py(p) { return (h * p / 100.0).toNumber(); }
    function pr(p) { return (w * p / 100.0).toNumber(); }
    function pt(x, y) { return [px(x), py(y)]; }

    function txt(dc, x, y, s, font, color, just) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.drawText(px(x), py(y), font, s, just);
    }

    // ============================================================
    function onUpdate(dc) {
        dc.setColor(Theme.BG, Theme.BG);
        dc.clear();

        var clock = System.getClockTime();

        drawBezel(dc);
        drawPanel(dc);
        drawTopDial(dc);
        drawNotification(dc);
        drawBodyBattery(dc);
        drawStepGauge(dc);
        drawMoon(dc);
        drawDigitalTime(dc, clock);
        drawCalendar(dc);
        drawHands(dc, clock);
    }

    // ---------- ikon ----------
    function drawHeart(dc, x, y, r, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x - r, y, r);
        dc.fillCircle(x + r, y, r);
        dc.fillPolygon([[x - 2 * r + 1, y + r / 2], [x + 2 * r - 1, y + r / 2], [x, y + 2.3 * r]]);
    }

    function drawFlame(dc, x, y, s, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y + s * 0.4, s * 0.6);
        dc.fillPolygon([[x - 0.58 * s, y + 0.3 * s], [x + 0.58 * s, y + 0.3 * s], [x + 0.15 * s, y - s]]);
    }

    function drawMountain(dc, x, y, s, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x - 1.3 * s, y + 0.6 * s], [x - 0.35 * s, y - 0.7 * s], [x + 0.25 * s, y + 0.1 * s],
                        [x + 0.7 * s, y - 0.4 * s], [x + 1.4 * s, y + 0.6 * s]]);
    }

    function drawPin(dc, x, y, s, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y - 0.3 * s, 0.7 * s);
        dc.fillPolygon([[x - 0.6 * s, y - 0.1 * s], [x + 0.6 * s, y - 0.1 * s], [x, y + 1.0 * s]]);
    }

    function drawBell(dc, x, y, s, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(x, y - 0.6 * s, 0.55 * s);
        dc.fillPolygon([[x - 0.9 * s, y + 0.5 * s], [x - 0.55 * s, y - 0.6 * s],
                        [x + 0.55 * s, y - 0.6 * s], [x + 0.9 * s, y + 0.5 * s]]);
        dc.fillRectangle(x - 1.1 * s, y + 0.4 * s, 2.2 * s, 0.3 * s);
        dc.fillCircle(x, y + 1.0 * s, 0.3 * s);
    }

    function drawBolt(dc, x, y, s, color) {
        dc.setColor(color, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([[x + 0.3 * s, y - 1.0 * s], [x - 0.7 * s, y + 0.15 * s], [x - 0.05 * s, y + 0.15 * s],
                        [x - 0.3 * s, y + 1.0 * s], [x + 0.7 * s, y - 0.2 * s], [x + 0.05 * s, y - 0.2 * s]]);
    }

    // ---------- bezel: cincin + 60 garis menit ----------
    function drawBezel(dc) {
        var rOut = cx - 1;

        dc.setColor(Theme.RING, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(12);
        dc.drawCircle(cx, cy, rOut - 8);

        for (var i = 0; i < 60; i++) {
            var a = Math.toRadians(i * 6);
            var s = Math.sin(a);
            var c = Math.cos(a);
            var accent = Theme.ACCENT_TICKS.indexOf(i) >= 0;
            var five = (i % 5 == 0);

            var r1 = rOut - 6;
            var pen = 1;
            if (accent) { r1 = rOut - 20; pen = 6; }
            else if (five) { r1 = rOut - 14; pen = 3; }

            dc.setPenWidth(pen);
            dc.setColor(accent ? Theme.ACCENT : Theme.TICK, Graphics.COLOR_TRANSPARENT);
            dc.drawLine(cx + r1 * s, cy - r1 * c, cx + rOut * s, cy - rOut * c);
        }
        dc.setPenWidth(1);
    }

    // ---------- panel kiri: HR, suhu/cuaca, kalori+jarak ----------
    function drawPanel(dc) {
        // baji abu-abu (dijaga tetap di dalam cincin bezel)
        dc.setColor(Theme.PANEL, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon([pt(11, 32), pt(20, 32), pt(42, 52), pt(52, 58), pt(60, 63), pt(7, 63)]);

        // strip kalori + jarak (berhenti sebelum lingkaran bulan)
        dc.setColor(Theme.STRIP, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(px(9), py(63), px(61), py(7));

        // detak jantung
        drawHeart(dc, px(13), py(34.5), pr(2.2), Theme.HEART);
        var hr = "--";
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.currentHeartRate != null) { hr = ai.currentHeartRate.format("%d"); }
        txt(dc, 9, 43, hr, Fonts.HEART_RATE, Theme.TEXT_DARK, L);
        txt(dc, 23, 44.5, "Bpm", Fonts.LABEL, Theme.TEXT_MUTED, L);

        // suhu
        txt(dc, 9, 50.5, "Temp.\u00B0C", Fonts.LABEL, Theme.TEXT_MUTED, L);
        var temp = "--";
        if (Toybox has :Weather) {
            var cond = Weather.getCurrentConditions();
            if (cond != null && cond.temperature != null) { temp = cond.temperature.format("%d"); }
        }
        txt(dc, 9, 57, temp, Fonts.TEMP, Theme.TEXT_DARK, L);

        // ikon cuaca sederhana (matahari + awan)
        dc.setColor(Theme.SUN, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px(41), py(53), pr(4.2));
        dc.setColor(Theme.CLOUD, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px(35), py(57.5), pr(3.1));
        dc.fillCircle(px(39), py(55.5), pr(4.1));
        dc.fillCircle(px(43), py(57.5), pr(3.1));
        dc.fillRectangle(px(35), py(57.5), px(8), py(3.1));

        // strip: kalori + jarak
        var am = ActivityMonitor.getInfo();
        var kcal = "--";
        var dist = "--";
        if (am != null) {
            if (am.calories != null) { kcal = am.calories.format("%d"); }
            if (am.distance != null) { dist = (am.distance / 100000.0).format("%.1f"); }
        }
        drawFlame(dc, px(12.5), py(66.8), pr(2.2), Theme.TEXT_DARK);
        txt(dc, 16, 66.5, kcal, Fonts.STRIP, Theme.TEXT_DARK, L);
        drawPin(dc, px(39), py(66.3), pr(1.8), Theme.TEXT_DARK);
        txt(dc, 43, 66.5, dist, Fonts.STRIP, Theme.TEXT_DARK, L);
    }

    // ---------- sub-dial atas: kalori & ketinggian ----------
    function drawTopDial(dc) {
        dc.setColor(Theme.DIAL_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px(50.3), py(23.9), pr(15.8));

        drawFlame(dc, px(50.3), py(13.8), pr(2.4), Theme.DIAL_TEXT);

        var kcal = "--";
        var am = ActivityMonitor.getInfo();
        if (am != null && am.calories != null) { kcal = am.calories.format("%d"); }
        txt(dc, 50.3, 20.5, kcal, Fonts.DIAL_VALUE, Theme.DIAL_TEXT, C);

        dc.setColor(Theme.DIAL_DIVIDER, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(px(40), py(25), px(60.5), py(25));

        var alt = "--";
        var ai = Activity.getActivityInfo();
        if (ai != null && ai.altitude != null) { alt = ai.altitude.format("%d"); }
        txt(dc, 50.3, 29.5, alt, Fonts.DIAL_VALUE, Theme.DIAL_TEXT, C);

        drawMountain(dc, px(50.3), py(35.5), pr(1.9), Theme.DIAL_TEXT);
    }

    // ---------- notifikasi (kiri atas) ----------
    function drawNotification(dc) {
        dc.setColor(Theme.DIAL_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px(23.2), py(23.9), pr(5.9));
        drawBell(dc, px(23.2), py(20.9), pr(1.6), Theme.DIAL_TEXT);
        var n = System.getDeviceSettings().notificationCount;
        txt(dc, 23.2, 27.3, n.format("%d"), Fonts.DIAL_VALUE, Theme.DIAL_TEXT, C);
    }

    // ---------- body battery (kanan atas) ----------
    function drawBodyBattery(dc) {
        dc.setColor(Theme.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px(75.5), py(24.2), pr(6.2));
        drawBolt(dc, px(75.5), py(20.9), pr(1.7), Theme.BB_ICON_TEXT);
        var bb = getBodyBattery();
        var s = (bb == null) ? "--" : bb.format("%d");
        txt(dc, 75.5, 27.6, s, Fonts.DIAL_VALUE, Theme.BB_ICON_TEXT, C);
    }

    function getBodyBattery() {
        if ((Toybox has :SensorHistory) && (SensorHistory has :getBodyBatteryHistory)) {
            var it = SensorHistory.getBodyBatteryHistory({ :period => 1 });
            if (it != null) {
                var sample = it.next();
                if (sample != null && sample.data != null) { return sample.data.toNumber(); }
            }
        }
        return null;
    }

    // ---------- gauge langkah (kanan tengah) ----------
    function drawStepGauge(dc) {
        var gx = 76.5;
        var gy = 48.9;
        var gcx = px(gx);
        var gcy = py(gy);

        dc.setColor(Theme.DIAL_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(gcx, gcy, pr(16.4));

        // garis skala (di antara label, dekat tepi)
        var tickAngles = [-60, 0, 60];
        dc.setColor(Theme.DIAL_TEXT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < tickAngles.size(); i++) {
            var a = Math.toRadians(tickAngles[i]);
            var r1 = pr(14.0);
            var r2 = pr(15.8);
            dc.drawLine(gcx + r1 * Math.sin(a), gcy - r1 * Math.cos(a),
                        gcx + r2 * Math.sin(a), gcy - r2 * Math.cos(a));
        }
        dc.setPenWidth(1);

        // label skala di lingkaran radius 12.2%
        var labels = ["20", "40", "60", "80"];
        var labelAngles = [-90, -30, 30, 90];
        for (var j = 0; j < 4; j++) {
            var la = Math.toRadians(labelAngles[j]);
            txt(dc, gx + 12.2 * Math.sin(la), gy - 12.2 * Math.cos(la), labels[j],
                Fonts.GAUGE_LABEL, Theme.DIAL_TEXT, C);
        }
        txt(dc, 70.5, 60.0, "E", Fonts.GAUGE_LABEL, Theme.DIAL_MUTED, C);
        txt(dc, 82.5, 60.0, "F", Fonts.GAUGE_LABEL, Theme.DIAL_MUTED, C);

        // jarum progres langkah: kiri (0%) -> kanan (100%)
        var am = ActivityMonitor.getInfo();
        var steps = 0;
        var pct = 0.0;
        if (am != null && am.steps != null) {
            steps = am.steps;
            if (am.stepGoal != null && am.stepGoal > 0) {
                pct = steps.toFloat() / am.stepGoal.toFloat();
                if (pct > 1.0) { pct = 1.0; }
            }
        }
        var na = Math.toRadians(-90 + 180 * pct);
        var len = pr(8.0);
        dc.setColor(Theme.ACCENT, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(5);
        dc.drawLine(gcx, gcy, gcx + len * Math.sin(na), gcy - len * Math.cos(na));
        dc.setPenWidth(1);
        dc.fillCircle(gcx, gcy, pr(1.3));

        txt(dc, gx, 54.8, steps.format("%d"), Fonts.DIAL_VALUE, Theme.DIAL_TEXT, C);
    }

    // ---------- lingkaran kecil kanan bawah (placeholder fase bulan) ----------
    function drawMoon(dc) {
        dc.setColor(Theme.DIAL_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(px(80.8), py(72), pr(4.3));
        dc.setColor(Theme.DIAL_MUTED, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(px(80.8), py(72), pr(4.3));
    }

    // ---------- jam digital ----------
    function drawDigitalTime(dc, clock) {
        var hr = clock.hour;
        var ampm = hr >= 12 ? "PM" : "AM";
        if (System.getDeviceSettings().is24Hour) {
            ampm = "";
        } else {
            hr = hr % 12;
            if (hr == 0) { hr = 12; }
        }
        var t = hr.format("%d") + ":" + clock.min.format("%02d");

        txt(dc, 49, 78, t, Fonts.TIME, Theme.TIME_TEXT, C);
        txt(dc, 21.5, 79, ampm, Fonts.AMPM, Theme.SECONDS_TEXT, C);
        if (!sleeping) {
            txt(dc, 76, 80, clock.sec.format("%02d"), Fonts.SECONDS, Theme.SECONDS_TEXT, C);
        }
    }

    // ---------- kalender (hari + tanggal) ----------
    function drawCalendar(dc) {
        var info = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);

        dc.setColor(Theme.BADGE_DAY_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(px(33), py(85.8), px(15.6), py(8), 6);
        dc.setColor(Theme.BADGE_DATE_BG, Graphics.COLOR_TRANSPARENT);
        dc.fillRoundedRectangle(px(50.3), py(85.8), px(13.5), py(8), 6);

        txt(dc, 40.8, 89.9, info.day_of_week.toString().toUpper(), Fonts.CALENDAR, Theme.BADGE_DAY_TXT, C);
        txt(dc, 57, 89.9, info.day.format("%d"), Fonts.CALENDAR, Theme.BADGE_DATE_TXT, C);
    }

    // ---------- jarum analog ----------
    function drawHands(dc, clock) {
        var hourA = Math.toRadians(((clock.hour % 12) + clock.min / 60.0) * 30);
        var minA  = Math.toRadians(clock.min * 6 + (sleeping ? 0 : clock.sec * 0.1));

        drawHand(dc, hourA, cx * 0.55, 7, 10);
        drawHand(dc, minA,  cx * 0.88, 5, 10);

        if (!sleeping) {
            var secA = Math.toRadians(clock.sec * 6);
            var s = Math.sin(secA);
            var c = Math.cos(secA);
            dc.setColor(Theme.SECOND_HAND, Graphics.COLOR_TRANSPARENT);
            dc.setPenWidth(2);
            dc.drawLine(cx - 28 * s, cy + 28 * c, cx + cx * 0.92 * s, cy - cx * 0.92 * c);
            dc.setPenWidth(1);
        }

        dc.setColor(Theme.HAND_FILL, Graphics.COLOR_TRANSPARENT);
        dc.fillCircle(cx, cy, 6);
        dc.setColor(Theme.HAND_EDGE, Graphics.COLOR_TRANSPARENT);
        dc.drawCircle(cx, cy, 6);
    }

    function drawHand(dc, a, len, wid, tail) {
        var s = Math.sin(a);
        var c = Math.cos(a);
        var m = 0.15 * len;
        var pts = [
            [cx - tail * s + wid * c, cy + tail * c + wid * s],
            [cx + m * s + wid * c,    cy - m * c + wid * s],
            [cx + len * s,            cy - len * c],
            [cx + m * s - wid * c,    cy - m * c - wid * s],
            [cx - tail * s - wid * c, cy + tail * c - wid * s]
        ];
        dc.setColor(Theme.HAND_FILL, Graphics.COLOR_TRANSPARENT);
        dc.fillPolygon(pts);
        dc.setColor(Theme.HAND_EDGE, Graphics.COLOR_TRANSPARENT);
        dc.setPenWidth(2);
        for (var i = 0; i < pts.size(); i++) {
            var p1 = pts[i];
            var p2 = pts[(i + 1) % pts.size()];
            dc.drawLine(p1[0], p1[1], p2[0], p2[1]);
        }
        dc.setPenWidth(1);
    }
}
