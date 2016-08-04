set(minuet_ICONS
  16-apps-minuet.png
  22-apps-minuet.png
  32-apps-minuet.png
  48-apps-minuet.png
  64-apps-minuet.png
  sc-apps-minuet.svgz
  16-actions-minuet-scales.svg
  16-actions-minuet-intervals.svg
  16-actions-minuet-chords.svg
  16-actions-minuet-rhythms.svg
  22-actions-minuet-scales.svg
  22-actions-minuet-intervals.svg
  22-actions-minuet-chords.svg
  22-actions-minuet-rhythms.svg
)

ecm_install_icons(ICONS ${minuet_ICONS} DESTINATION ${ICON_INSTALL_DIR} THEME hicolor)
