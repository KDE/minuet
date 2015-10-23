set(minuet_ICONS
  hi16-apps-minuet.png
  hi22-apps-minuet.png
  hi32-apps-minuet.png
  hi48-apps-minuet.png
  hisc-apps-minuet.svgz
)

ecm_install_icons(ICONS ${minuet_ICONS} DESTINATION ${ICON_INSTALL_DIR} THEME hicolor)
