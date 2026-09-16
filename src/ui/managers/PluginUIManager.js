const { getIconForPlugin, createIconSvg, CURATED_ICONS } = require('../icons/PluginIconMap')

class PluginUIManager {
  constructor(application) {
    this.application = application
    this.$activeContextMenu = null
    this.$activeIconPicker = null
    this._searchQuery = ''
    this._initGlobalContextMenuDismiss()
  }

  static RECENT_LIMIT = 5

  setSearchQuery(query) {
    this._searchQuery = String(query || '').trim().toLowerCase()
    this.reorderPluginList()
  }

  _getRecent() {
    try {
      const settings = this.application.settings
      if (settings && settings.get) {
        const list = settings.get('plugins.recentlyUsed')
        return Array.isArray(list) ? list : []
      }
    } catch (_) {}
    return []
  }

  _recordRecent(pluginName) {
    if (!pluginName) return
    try {
      const settings = this.application.settings
      if (settings && settings.get && settings.update) {
        const list = this._getRecent().filter(n => n !== pluginName)
        list.unshift(pluginName)
        settings.update('plugins.recentlyUsed', list.slice(0, PluginUIManager.RECENT_LIMIT))
      }
    } catch (_) {}
    this.renderRecentRow()
  }

  _openPlugin(name) {
    this._recordRecent(name)
    const mode = this.application.settings.get('plugins.defaultDisplayMode', 'inline')
    if (mode === 'inline' && this.application.inlinePluginManager) {
      this.application.inlinePluginManager.open(name)
    } else {
      this.application.dispatch.open(name)
    }
  }

  renderRecentRow() {
    const $row = $('#pluginRecentRow')
    const $chips = $('#pluginRecentChips')
    if (!$row.length || !$chips.length || !this.application.$pluginList) return

    const customIcons = this._getCustomIcons()
    const recent = this._getRecent().filter(name => {
      const $tile = this.application.$pluginList.find(`li[data-plugin-name="${name}"]`)
      return $tile.length > 0 && $tile.data('plugin-type') === 'ui'
    })

    $chips.empty()
    if (recent.length === 0 || this._searchQuery) {
      $row.addClass('hidden')
      return
    }

    recent.forEach(name => {
      const $chip = $(`<button type="button" class="plugin-recent-chip" title="Open ${name}"></button>`)
      $chip.append(createIconSvg(getIconForPlugin(name, 'ui', customIcons)))
      $chip.append($('<span></span>').text(name))
      $chip.on('click', (e) => {
        e.stopPropagation()
        this._openPlugin(name)
      })
      $chips.append($chip)
    })
    $row.removeClass('hidden')
  }

  _initGlobalContextMenuDismiss() {
    $(document).on('click', (e) => {
      if (!$(e.target).closest('.plugin-context-menu').length) {
        this.hideContextMenu()
      }
      if (this.$activeIconPicker && !$(e.target).closest('.plugin-icon-picker').length) {
        this._closeIconPicker()
      }
    })
    $(document).on('contextmenu', (e) => {
      if (!$(e.target).closest('.plugin-grid-tile').length) {
        this.hideContextMenu()
      }
    })
  }

  _getCustomIcons() {
    try {
      const settings = this.application.settings
      if (settings && settings.get) {
        return settings.get('plugins.sidebar.customIcons') || {}
      }
    } catch (_) {}
    return {}
  }

  _getHiddenPlugins() {
    try {
      const settings = this.application.settings
      if (settings && settings.get) {
        return settings.get('plugins.sidebar.hiddenPlugins') || []
      }
    } catch (_) {}
    return []
  }

  renderItems({ name, type, description, author = 'Sxip', version = '' } = {}) {
    const customIcons = this._getCustomIcons()
    const iconName = getIconForPlugin(name, type, customIcons)
    const iconSvg = createIconSvg(iconName, 'plugin-lucide-icon')

    const isUI = type === 'ui'
    const typeBadge = isUI
      ? '<span class="plugin-type-badge">UI</span>'
      : '<span class="plugin-type-badge">Game</span>'

    const statusColor = isUI ? 'bg-red-500' : 'bg-yellow-500'

    const hidden = this._getHiddenPlugins().includes(name)
    const descText = description || 'No description available'
    const openHint = isUI
      ? '<span class="plugin-tile-open" aria-hidden="true"><i class="fas fa-chevron-right"></i></span>'
      : ''

    const $plugin = $(`
      <li class="plugin-grid-tile group relative ${isUI ? 'cursor-pointer' : ''}"
          data-plugin-name="${name}" data-plugin-type="${type}" data-plugin-search="${`${name} ${author} ${descText}`.toLowerCase().replace(/"/g, '')}" title="${description || name}" ${isUI ? 'tabindex="0" role="button"' : ''} ${hidden ? 'style="display:none"' : ''}>
        <div class="plugin-tile-head">
          <div class="plugin-icon-container">
            ${iconSvg}
            <span class="plugin-status-indicator ${statusColor}"></span>
          </div>
          <div class="plugin-tile-meta">
            <div class="plugin-tile-title-row">
              <span class="plugin-tile-name">${name}</span>
              ${typeBadge}
            </div>
            <span class="plugin-tile-sub">${author}${version ? ' \u00b7 v' + version : ''}</span>
          </div>
          ${openHint}
        </div>
        <p class="plugin-tile-desc">${descText}</p>
      </li>
    `)

    if (isUI) {
      $plugin.on('click', (e) => {
        if (!$(e.target).closest('.plugin-context-menu').length) {
          this._openPlugin(name)
        }
      })
      $plugin.on('keydown', (e) => {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault()
          this._openPlugin(name)
        }
      })
    }

    $plugin.on('contextmenu', (e) => {
      e.preventDefault()
      e.stopPropagation()
      this.showContextMenu(name, type, e.clientX, e.clientY)
    })

    return $plugin
  }

  showContextMenu(pluginName, pluginType, x, y) {
    this.hideContextMenu()
    this._closeIconPicker()

    const menuItems = []

    menuItems.push({
      label: 'View Info',
      icon: 'fa-info-circle',
      action: () => this.application.pluginInfoModalManager.show(pluginName)
    })

    if (pluginType === 'ui') {
      menuItems.push({
        label: 'Open Inline',
        icon: 'fa-columns',
        action: () => {
          this._recordRecent(pluginName)
          if (this.application.inlinePluginManager) {
            this.application.inlinePluginManager.open(pluginName)
          } else {
            this.application.dispatch.open(pluginName)
          }
        }
      })
      menuItems.push({
        label: 'Open in New Window',
        icon: 'fa-external-link-alt',
        action: () => {
          this._recordRecent(pluginName)
          this.application.dispatch.open(pluginName)
        }
      })
    }

    menuItems.push({ separator: true })

    menuItems.push({
      label: 'Change Icon',
      icon: 'fa-palette',
      action: () => this._showIconPicker(pluginName, pluginType, x, y)
    })

    const isHidden = this._getHiddenPlugins().includes(pluginName)
    if (isHidden) {
      menuItems.push({
        label: 'Show Plugin',
        icon: 'fa-eye',
        action: () => this._unhidePlugin(pluginName)
      })
    } else {
      menuItems.push({
        label: 'Hide Plugin',
        icon: 'fa-eye-slash',
        action: () => this._hidePlugin(pluginName)
      })
    }

    menuItems.push({ separator: true })

    menuItems.push({
      label: 'Uninstall',
      icon: 'fa-trash-alt',
      cssClass: 'text-error-red',
      action: () => this._uninstallPlugin(pluginName)
    })

    const $menu = $('<div class="plugin-context-menu"></div>')

    menuItems.forEach(item => {
      if (item.separator) {
        $menu.append('<div class="plugin-context-menu-separator"></div>')
        return
      }
      const $item = $(`
        <div class="plugin-context-menu-item ${item.cssClass || ''}">
          <i class="fas ${item.icon} text-xs"></i>
          <span>${item.label}</span>
        </div>
      `)
      $item.on('click', (e) => {
        e.stopPropagation()
        this.hideContextMenu()
        item.action()
      })
      $menu.append($item)
    })

    const viewportW = window.innerWidth
    const viewportH = window.innerHeight
    let posX = x
    let posY = y

    $menu.css({ left: posX, top: posY })
    $('body').append($menu)

    const menuW = $menu.outerWidth()
    const menuH = $menu.outerHeight()
    if (posX + menuW > viewportW) posX = viewportW - menuW - 8
    if (posY + menuH > viewportH) posY = viewportH - menuH - 8
    $menu.css({ left: posX, top: posY })

    this.$activeContextMenu = $menu
  }

  hideContextMenu() {
    if (this.$activeContextMenu) {
      this.$activeContextMenu.remove()
      this.$activeContextMenu = null
    }
  }

  _showIconPicker(pluginName, pluginType, anchorX, anchorY) {
    this._closeIconPicker()

    const $picker = $(`
      <div class="plugin-icon-picker">
        <div class="icon-picker-label">Pick icon for ${pluginName}</div>
        <div class="icon-picker-grid themed-scrollbar">
        </div>
        <div style="margin-top:8px; display:flex; justify-content:flex-end; flex-shrink:0;">
          <button class="reset-icon-btn">Reset to default</button>
        </div>
      </div>
    `)

    const $grid = $picker.find('.icon-picker-grid')
    CURATED_ICONS.forEach(name => {
      const svg = createIconSvg(name)
      const $btn = $(`<button class="icon-picker-btn" title="${name}"></button>`)
      $btn.append(svg)
      $btn.on('click', (e) => {
        e.stopPropagation()
        this._setCustomIcon(pluginName, name)
        this._closeIconPicker()
      })
      $grid.append($btn)
    })

    $picker.find('.reset-icon-btn').on('click', (e) => {
      e.stopPropagation()
      this._resetCustomIcon(pluginName, pluginType)
      this._closeIconPicker()
    })

    $('body').append($picker)

    const pickerW = $picker.outerWidth()
    const pickerH = $picker.outerHeight()
    let posX = anchorX + 8
    let posY = anchorY
    if (posX + pickerW > window.innerWidth) posX = anchorX - pickerW - 8
    if (posY + pickerH > window.innerHeight) posY = window.innerHeight - pickerH - 8
    if (posY < 8) posY = 8
    $picker.css({ left: posX, top: posY })

    this.$activeIconPicker = $picker
  }

  _closeIconPicker() {
    if (this.$activeIconPicker) {
      this.$activeIconPicker.remove()
      this.$activeIconPicker = null
    }
  }

  _setCustomIcon(pluginName, iconName) {
    try {
      const settings = this.application.settings
      if (settings && settings.get && settings.update) {
        const icons = settings.get('plugins.sidebar.customIcons') || {}
        icons[pluginName] = iconName
        settings.update('plugins.sidebar.customIcons', icons)
      }
    } catch (_) {}
    this.updateTileIcon(pluginName, iconName)
  }

  _resetCustomIcon(pluginName, pluginType) {
    try {
      const settings = this.application.settings
      if (settings && settings.get && settings.update) {
        const icons = settings.get('plugins.sidebar.customIcons') || {}
        delete icons[pluginName]
        settings.update('plugins.sidebar.customIcons', icons)
      }
    } catch (_) {}
    const defaultIcon = getIconForPlugin(pluginName, pluginType, {})
    this.updateTileIcon(pluginName, defaultIcon)
  }

  _hidePlugin(pluginName) {
    try {
      const settings = this.application.settings
      if (settings && settings.get && settings.update) {
        const hidden = settings.get('plugins.sidebar.hiddenPlugins') || []
        if (!hidden.includes(pluginName)) {
          hidden.push(pluginName)
          settings.update('plugins.sidebar.hiddenPlugins', hidden)
        }
      }
    } catch (_) {}

    const $tile = this.application.$pluginList.find(`li[data-plugin-name="${pluginName}"]`)
    $tile.fadeOut(200)
    setTimeout(() => {
      this.updateEmptyPluginMessage()
      this._updateHiddenButtonVisibility()
    }, 250)
  }

  _unhidePlugin(pluginName) {
    try {
      const settings = this.application.settings
      if (settings && settings.get && settings.update) {
        let hidden = settings.get('plugins.sidebar.hiddenPlugins') || []
        hidden = hidden.filter(n => n !== pluginName)
        settings.update('plugins.sidebar.hiddenPlugins', hidden)
      }
    } catch (_) {}

    const $tile = this.application.$pluginList.find(`li[data-plugin-name="${pluginName}"]`)
    $tile.fadeIn(200)
    setTimeout(() => {
      this.updateEmptyPluginMessage()
      this._updateHiddenButtonVisibility()
    }, 250)
  }

  _updateHiddenButtonVisibility() {
    const $btn = $('#showHiddenPluginsBtn')
    if (!$btn.length) return
    const hidden = this._getHiddenPlugins()
    if (hidden.length > 0) {
      $btn.removeClass('hidden')
    } else {
      $btn.addClass('hidden')
    }
  }

  _uninstallPlugin(pluginName) {
    const { ipcRenderer } = require('electron')
    const path = require('path')
    const fs = require('fs')

    const isBundled = this._isBundledPlugin(pluginName)
    if (isBundled) {
      this.application.consoleMessage({
        type: 'error',
        message: `"${pluginName}" is a bundled plugin and cannot be uninstalled.`
      })
      return
    }

    if (!confirm(`Are you sure you want to uninstall "${pluginName}"?`)) return

    ;(async () => {
      try {
        const userPluginsPath = await ipcRenderer.invoke('get-user-plugins-path')
        const pluginDir = path.join(userPluginsPath, pluginName)
        if (fs.existsSync(pluginDir)) {
          fs.rmSync(pluginDir, { recursive: true, force: true })
        }

        this.application.consoleMessage({
          type: 'success',
          message: `Plugin "${pluginName}" has been uninstalled.`
        })

        if (this.application.dispatch && typeof this.application.dispatch.refresh === 'function') {
          await this.application.dispatch.refresh()
        }
      } catch (error) {
        this.application.consoleMessage({
          type: 'error',
          message: `Failed to uninstall "${pluginName}": ${error.message}`
        })
      }
    })()
  }

  _isBundledPlugin(pluginName) {
    const fs = require('fs')
    const path = require('path')
    try {
      const bundledPath = path.resolve('plugins', pluginName)
      return fs.existsSync(bundledPath)
    } catch (_) {}
    return false
  }

  updatePluginStatusIndicator(pluginName, isOpen) {
    if (!this.application.$pluginList || this.application.$pluginList.length === 0) {
      return
    }

    const $listItem = this.application.$pluginList.find(`li[data-plugin-name="${pluginName}"]`)
    if ($listItem.length === 0) {
      return
    }

    const $indicator = $listItem.find('.plugin-status-indicator')
    if ($indicator.length === 0) {
      return
    }

    const pluginType = $listItem.data('plugin-type')
    if (pluginType === 'ui') {
      if (isOpen) {
        $indicator.removeClass('bg-red-500 bg-yellow-500').addClass('bg-green-500')
      } else {
        $indicator.removeClass('bg-green-500 bg-yellow-500').addClass('bg-red-500')
      }
    } else {
      $indicator.removeClass('bg-red-500 bg-green-500').addClass('bg-yellow-500')
    }
  }

  updateEmptyPluginMessage() {
    const $emptyPluginMessage = $('#emptyPluginMessage')
    const $searchEmpty = $('#pluginSearchEmpty')
    const visiblePlugins = this.application.$pluginList.children('li:visible').length
    if (this._searchQuery) {
      $emptyPluginMessage.addClass('hidden')
      $searchEmpty.toggleClass('hidden', visiblePlugins > 0)
      return
    }
    $searchEmpty.addClass('hidden')
    if ($emptyPluginMessage.length > 0) {
      $emptyPluginMessage.toggleClass('hidden', visiblePlugins > 0)
    }
  }

  reorderPluginList() {
    if (!this.application.$pluginList) return

    let sortMode = 'type'
    let customOrder = []
    let hiddenPlugins = []

    try {
      const settings = this.application.settings
      if (settings && settings.get) {
        sortMode = settings.get('plugins.sidebar.sortMode') || 'type'
        customOrder = settings.get('plugins.sidebar.customOrder') || []
        hiddenPlugins = settings.get('plugins.sidebar.hiddenPlugins') || []
      }
    } catch (_) {}

    const hideGamePlugins = this._getHideGamePlugins()
    const $items = this.application.$pluginList.children('li').detach()

    const sorted = $items.toArray().sort((a, b) => {
      const nameA = $(a).data('plugin-name')
      const nameB = $(b).data('plugin-name')
      const typeA = $(a).data('plugin-type')
      const typeB = $(b).data('plugin-type')

      if (sortMode === 'alphabetical') {
        return nameA.localeCompare(nameB)
      }

      if (sortMode === 'custom') {
        const idxA = customOrder.indexOf(nameA)
        const idxB = customOrder.indexOf(nameB)
        const posA = idxA === -1 ? 9999 : idxA
        const posB = idxB === -1 ? 9999 : idxB
        if (posA !== posB) return posA - posB
        return nameA.localeCompare(nameB)
      }

      const typeOrder = { ui: 0, game: 1 }
      const tA = typeOrder[typeA] !== undefined ? typeOrder[typeA] : 2
      const tB = typeOrder[typeB] !== undefined ? typeOrder[typeB] : 2
      if (tA !== tB) return tA - tB
      return nameA.localeCompare(nameB)
    })

    const query = this._searchQuery
    sorted.forEach(el => {
      const name = $(el).data('plugin-name')
      const type = $(el).data('plugin-type')
      const searchText = String($(el).attr('data-plugin-search') || String(name).toLowerCase())
      const matchesSearch = !query || searchText.indexOf(query) !== -1
      const shouldHide = hiddenPlugins.includes(name) || (hideGamePlugins && type === 'game') || !matchesSearch
      if (shouldHide) {
        $(el).hide()
      } else {
        $(el).show()
      }
      this.application.$pluginList.append(el)
    })

    this.updateEmptyPluginMessage()
    this.renderRecentRow()
  }

  _getHideGamePlugins() {
    try {
      const settings = this.application.settings
      if (settings && settings.get) {
        return settings.get('ui.hideGamePlugins', false)
      }
    } catch (_) {}
    return false
  }

  cycleSortMode() {
    const modes = ['type', 'alphabetical']
    let currentMode = 'type'
    try {
      const settings = this.application.settings
      if (settings && settings.get) {
        currentMode = settings.get('plugins.sidebar.sortMode') || 'type'
      }
    } catch (_) {}

    const currentIdx = modes.indexOf(currentMode)
    const nextMode = modes[(currentIdx + 1) % modes.length]

    try {
      const settings = this.application.settings
      if (settings && settings.update) {
        settings.update('plugins.sidebar.sortMode', nextMode)
      }
    } catch (_) {}

    this.reorderPluginList()
    return nextMode
  }

  updateTileIcon(pluginName, iconName) {
    const $tile = this.application.$pluginList.find(`li[data-plugin-name="${pluginName}"]`)
    if ($tile.length === 0) return

    const $container = $tile.find('.plugin-icon-container')
    $container.find('svg').remove()
    const newSvg = createIconSvg(iconName, 'plugin-lucide-icon')
    $container.prepend(newSvg)
  }

  showHiddenPluginsOverlay() {
    const hidden = this._getHiddenPlugins()
    if (hidden.length === 0) {
      this.application.consoleMessage({
        type: 'notify',
        message: 'No hidden plugins.'
      })
      return
    }

    hidden.forEach(name => {
      const $tile = this.application.$pluginList.find(`li[data-plugin-name="${name}"]`)
      if ($tile.length) {
        $tile.fadeIn(200).css('opacity', '0.5')
      }
    })

    this.application.consoleMessage({
      type: 'notify',
      message: `${hidden.length} hidden plugin(s) revealed. Right-click to unhide them.`
    })
  }
}

module.exports = PluginUIManager
