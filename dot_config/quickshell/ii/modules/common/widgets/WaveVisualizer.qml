import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick

Canvas { // Visualizer (cava-style bars, ported from muser dashboard)
    id: root
    property list<var> points
    property list<var> smoothPoints
    property real maxVisualizerValue: 1000
    property int smoothing: 2
    property bool live: true
    property color color: Appearance.m3colors.m3primary

    property real fillAlpha: 1.0

    property bool centerBass: false

    property bool horizontalFade: false

    property real barGap: 3
    property real minBarHeight: 2
    property real glowRadius: 8

    onPointsChanged: () => {
        root.requestPaint()
    }
    onColorChanged: () => {
        root.requestPaint()
    }

    anchors.fill: parent
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);

        var points = root.points;
        var maxVal = root.maxVisualizerValue || 1;
        var h = height;
        var w = width;
        var n = points.length;
        if (n < 2) return;

        // Smoothing: simple moving average (optional)
        var smoothWindow = root.smoothing; // adjust for more/less smoothing
        root.smoothPoints = [];
        for (var i = 0; i < n; ++i) {
            var sum = 0, count = 0;
            for (var j = -smoothWindow; j <= smoothWindow; ++j) {
                var idx = Math.max(0, Math.min(n - 1, i + j));
                sum += points[idx];
                count++;
            }
            root.smoothPoints.push(sum / count);
        }
        if (!root.live) root.smoothPoints.fill(0); // If not playing, show no points

        if (root.centerBass && n > 0) {
            var reordered = new Array(n);
            var mid = Math.floor(n / 2);
            for (var k = 0; k < n; k++) {
                if (k % 2 === 0) {
                    reordered[mid + Math.floor(k / 2)] = root.smoothPoints[k];
                } else {
                    reordered[mid - Math.ceil(k / 2)] = root.smoothPoints[k];
                }
            }
            // Fill any empty spots if there's an odd array len logic edge case
            for (var m = 0; m < n; m++) if (reordered[m] === undefined) reordered[m] = 0;
            root.smoothPoints = reordered;
        }

        // Cap the gap on narrow widgets so bars never collapse to slivers
        var gap = Math.min(root.barGap, (w / n) * 0.35);
        var barWidth = (w - gap * (n - 1)) / n;

        // White base quickly blending into an accent-dominant top
        var grad = ctx.createLinearGradient(0, h, 0, 0);
        grad.addColorStop(0, "#ffffff");
        grad.addColorStop(0.12, "#ffffff");
        grad.addColorStop(0.45, root.color);
        grad.addColorStop(1, root.color);
        ctx.fillStyle = grad;
        ctx.shadowColor = Qt.rgba(root.color.r, root.color.g, root.color.b, 0.55);
        ctx.shadowBlur = root.glowRadius;

        for (var i = 0; i < n; ++i) {
            var barHeight = Math.max(root.minBarHeight, (root.smoothPoints[i] / maxVal) * h);
            var x = i * (barWidth + gap);
            var alpha = root.fillAlpha;
            if (root.horizontalFade) {
                var t = n > 1 ? i / (n - 1) : 0;
                // Fade bars out toward both horizontal edges
                if (t < 0.2) alpha *= t / 0.2;
                else if (t > 0.8) alpha *= (1 - t) / 0.2;
            }
            ctx.globalAlpha = alpha;
            ctx.fillRect(x, h - barHeight, barWidth, barHeight);
        }
        ctx.globalAlpha = 1;
    }
}
