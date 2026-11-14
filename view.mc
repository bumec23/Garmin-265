import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;
import Toybox.Time.Gregorian;

class Minimal265View extends WatchUi.WatchFace {

    private var _isSleeping as Boolean = false;

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc as Dc) as Void {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onUpdate(dc as Dc) as Void {

        // 1. WAKTU
        var clockTime = System.getClockTime();
        var hours = clockTime.hour;
        var is24 = System.getDeviceSettings().is24Hour;
        var useMilitary = false;

        if (is24) {
            var prop = Application.Properties.getValue("UseMilitaryFormat");
            useMilitary = (prop != null && prop == true);
        } else {
            hours = hours % 12;
            if (hours == 0) {
                hours = 12;
            }
        }

        var timeString;
        if (_isSleeping) {
            // Mode hemat daya: tanpa detik
            if (useMilitary) {
                timeString = Lang.format("$1$$2$", [hours.format("%02d"), clockTime.min.format("%02d")]);
            } else {
                timeString = Lang.format("$1$:$2$", [hours.format(is24 ? "%02d" : "%d"), clockTime.min.format("%02d")]);
            }
        } else {
            if (useMilitary) {
                timeString = Lang.format("$1$$2$:$3$", [hours.format("%02d"), clockTime.min.format("%02d"), clockTime.sec.format("%02d")]);
            } else {
                timeString = Lang.format("$1$:$2$:$3$", [hours.format(is24 ? "%02d" : "%d"), clockTime.min.format("%02d"), clockTime.sec.format("%02d")]);
            }
        }

        var timeLabel = View.findDrawableById("TimeLabel") as WatchUi.Text?;
        if (timeLabel != null) {
            timeLabel.setText(timeString);
        }

        // 2. TANGGAL
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$/$2$/$3$", [
            dateInfo.day.format("%02d"),
            dateInfo.month.format("%02d"),
            dateInfo.year.format("%04d")
        ]);

        var dateLabel = View.findDrawableById("DateLabel") as WatchUi.Text?;
        if (dateLabel != null) {
            dateLabel.setText(dateString);
        }

        // 3. GAMBAR
        View.onUpdate(dc);
    }

    function onEnterSleep() as Void {
        _isSleeping = true;
        WatchUi.requestUpdate();
    }

    function onExitSleep() as Void {
        _isSleeping = false;
        WatchUi.requestUpdate();
    }

    function onShow() as Void {}
    function onHide() as Void {}
}
