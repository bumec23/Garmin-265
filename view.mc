
import Toybox.Application;
import Toybox.Graphics;
import Toybox.Lang;
import Toybox.System;
import Toybox.WatchUi;
import Toybox.Time;

class Minimal265View extends WatchUi.WatchFace {

    function initialize() {
        WatchFace.initialize();
    }

    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    function onShow() {
    }

    function onUpdate(dc) {

        // =================================
        // 1. READ CURRENT TIME
        // =================================

        var clockTime = System.getClockTime();
        var hours = clockTime.hour;

        var timeFormat = "$1$:$2$:$3$";

        // 12 / 24 Hour Format
        if (!System.getDeviceSettings().is24Hour) {

            hours = hours % 12;

            if (hours == 0) {
                hours = 12;
            }

        } else if (Application.Properties.getValue("UseMilitaryFormat")) {

            timeFormat = "$1$$2$:$3$";
            hours = hours.format("%02d");
        }

        // Format HH:MM:SS
        var timeString = Lang.format(
            timeFormat,
            [
                hours,
                clockTime.min.format("%02d"),
                clockTime.sec.format("%02d")
            ]
        );

        // Update Time Label
        var timeLabel = View.findDrawableById("TimeLabel") as WatchUi.Text?;

        if (timeLabel != null) {
            timeLabel.setText(timeString);
        }


        // =================================
        // 2. READ CURRENT DATE
        // =================================

        var dateInfo = Time.Gregorian.info(
            Time.now(),
            Time.FORMAT_SHORT
        );

        // Format DD/MM/YYYY
        var dateString = Lang.format(
            "$1$/$2$/$3$",
            [
                dateInfo.day.format("%02d"),
                dateInfo.month.format("%02d"),
                dateInfo.year.format("%04d")
            ]
        );

        // Update Date Label
        var dateLabel = View.findDrawableById("DateLabel") as WatchUi.Text?;

        if (dateLabel != null) {
        dateLabel.setText("TEST DATE");
        }


        // =================================
        // 3. REFRESH DISPLAY
        // =================================

        View.onUpdate(dc);
    }

    function onHide() {
    }

    function onExitSleep() {
    }

    function onEnterSleep() {
    }
}
