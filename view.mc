import Toybox.Activity;
import Toybox.ActivityMonitor;
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

    private function setLabel(id as String, text as String) as Void {
        var label = View.findDrawableById(id) as WatchUi.Text?;
        if (label != null) {
            label.setText(text);
        }
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

        var hh = hours.format(is24 ? "%02d" : "%d");
        var mm = clockTime.min.format("%02d");
        var ss = clockTime.sec.format("%02d");

        var timeString;
        if (_isSleeping) {
            timeString = useMilitary ? (hh + mm) : (hh + ":" + mm);
        } else {
            timeString = useMilitary ? (hh + mm + ":" + ss) : (hh + ":" + mm + ":" + ss);
        }
        setLabel("TimeLabel", timeString);

        // 2. TANGGAL
        var dateInfo = Gregorian.info(Time.now(), Time.FORMAT_SHORT);
        var dateString = Lang.format("$1$/$2$/$3$", [
            dateInfo.day.format("%02d"),
            dateInfo.month.format("%02d"),
            dateInfo.year.format("%04d")
        ]);
        setLabel("DateLabel", dateString);

        // 3. BATERAI
        var batt = System.getSystemStats().battery.toNumber();
        setLabel("BatteryLabel", batt.format("%d") + "%");
        var battLabel = View.findDrawableById("BatteryLabel") as WatchUi.Text?;
        if (battLabel != null) {
            battLabel.setColor(batt <= 20 ? Graphics.COLOR_RED : Graphics.COLOR_GREEN);
        }

        // 4. DETAK JANTUNG
        var hrString = "--";
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
        setLabel("HeartLabel", "HR " + hrString);
        // 5. LANGKAH
        var steps = ActivityMonitor.getInfo().steps;
        setLabel("StepsLabel", "ST " + (steps != null ? steps.format("%d") : "--"));

        // 6. GAMBAR
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
