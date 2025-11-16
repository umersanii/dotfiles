#!/usr/bin/env bash
# Script to apply custom hardcoded colors for waybar

PRIMARY_COLOR=$1
SECONDARY_COLOR=$2

if [ -z "$PRIMARY_COLOR" ] || [ -z "$SECONDARY_COLOR" ]; then
    echo "Usage: $0 <primary_color> <secondary_color>"
    exit 1
fi

# Remove # from colors if present
PRIMARY_COLOR="${PRIMARY_COLOR#\#}"
SECONDARY_COLOR="${SECONDARY_COLOR#\#}"

# Convert hex to rgba with alpha for container colors
# Extract RGB components from hex
PRIMARY_R=$((16#${PRIMARY_COLOR:0:2}))
PRIMARY_G=$((16#${PRIMARY_COLOR:2:2}))
PRIMARY_B=$((16#${PRIMARY_COLOR:4:2}))
SECONDARY_R=$((16#${SECONDARY_COLOR:0:2}))
SECONDARY_G=$((16#${SECONDARY_COLOR:2:2}))
SECONDARY_B=$((16#${SECONDARY_COLOR:4:2}))

# Create rgba versions with alpha 0.87 (dd in hex)
PRIMARY_CONTAINER="rgba($PRIMARY_R, $PRIMARY_G, $PRIMARY_B, 0.87)"
SECONDARY_CONTAINER="rgba($SECONDARY_R, $SECONDARY_G, $SECONDARY_B, 0.87)"

# For hover effects - check if it's black/white theme
if [ "$PRIMARY_COLOR" = "000000" ] && [ "$SECONDARY_COLOR" = "ffffff" ]; then
    # Black primary, white secondary - invert on hover (black bg, white text)
    HOVER_BG="#000000"
    HOVER_TEXT="#ffffff"
    HOVER_BORDER="#000000"
    ON_PRIMARY_TEXT="#ffffff"
    ON_SECONDARY_TEXT="#000000"
else
    # Normal behavior
    HOVER_BG="rgba($PRIMARY_R, $PRIMARY_G, $PRIMARY_B, 0.87)"
    HOVER_TEXT="#ffffff"
    HOVER_BORDER="#${PRIMARY_COLOR}"
    ON_PRIMARY_TEXT="#ffffff"
    ON_SECONDARY_TEXT="#000000"
fi

# Update the colors files
echo "#$PRIMARY_COLOR" > "$HOME/.config/ml4w/colors/primary"
echo "#$SECONDARY_COLOR" > "$HOME/.config/ml4w/colors/secondary"

# Generate a custom colors.css for waybar
cat > "$HOME/.config/waybar/colors.css" << EOF
/*
* Css Colors
* Custom hardcoded colors
*/
@define-color blur_background rgba(26, 17, 15, 0.3);
@define-color blur_background8 rgba(26, 17, 15, 0.8);

@define-color background #1a110f;
@define-color error #ffb4ab;
@define-color error_container #93000a;
@define-color inverse_on_surface #392e2b;
@define-color inverse_primary #${PRIMARY_COLOR};
@define-color inverse_surface #f1dfda;
@define-color on_background #f1dfda;
@define-color on_error #690005;
@define-color on_error_container #ffdad6;
@define-color on_primary ${ON_PRIMARY_TEXT};
@define-color on_primary_container #ffdbd0;
@define-color on_primary_fixed #390c00;
@define-color on_primary_fixed_variant #723520;
@define-color on_secondary ${ON_SECONDARY_TEXT};
@define-color on_secondary_container #ffdbd0;
@define-color on_secondary_fixed #2c160e;
@define-color on_secondary_fixed_variant #5d4036;
@define-color on_surface #f1dfda;
@define-color on_surface_variant #d8c2bb;
@define-color on_tertiary #3a3005;
@define-color on_tertiary_container #f3e2a7;
@define-color on_tertiary_fixed #221b00;
@define-color on_tertiary_fixed_variant #51461a;
@define-color outline #a08d87;
@define-color outline_variant #53433f;
@define-color primary #${PRIMARY_COLOR};
@define-color primary_container ${PRIMARY_CONTAINER};
@define-color primary_fixed #ffdbd0;
@define-color primary_fixed_dim #ffb59d;
@define-color scrim #000000;
@define-color secondary #${SECONDARY_COLOR};
@define-color secondary_container ${SECONDARY_CONTAINER};
@define-color secondary_fixed #ffdbd0;
@define-color secondary_fixed_dim #e7bdb0;
@define-color shadow #000000;
@define-color source_color #${PRIMARY_COLOR};
@define-color surface #1a110f;
@define-color surface_bright #423733;
@define-color surface_container #271d1b;
@define-color surface_container_high #322825;
@define-color surface_container_highest #3d322f;
@define-color surface_container_low #231917;
@define-color surface_container_lowest #140c0a;
@define-color surface_dim #1a110f;
@define-color surface_tint #${PRIMARY_COLOR};
@define-color surface_variant #53433f;
@define-color tertiary #d7c68d;
@define-color tertiary_container #51461a;
@define-color tertiary_fixed #f3e2a7;
@define-color tertiary_fixed_dim #d7c68d;

/* Custom hover colors */
@define-color hover_background ${HOVER_BG};
@define-color hover_text ${HOVER_TEXT};
@define-color hover_border ${HOVER_BORDER};
EOF

echo "Custom colors applied: Primary=$PRIMARY_COLOR, Secondary=$SECONDARY_COLOR"
