const { shell } = require('electron')

/**
 * The settings modal's Burrow tab: Burrow mode on or off, the server's
 * address, and which game client to play with (BurrowMode.js keeps the rest
 * of the launcher in step). Each change is saved as it is made.
 */
class BurrowSettingsManager {
  static bind ($modal, app) {
    const burrowMode = app.burrowMode
    if (!burrowMode) return

    const $toggle = $modal.find('#burrowModeToggle')
    const $server = $modal.find('#burrowServerInput')
    const $status = $modal.find('#burrowServerStatus')
    const $check = $modal.find('#burrowCheckBtn')
    const $clients = $modal.find('input[name="burrowClient"]')

    const say = (text, isError) => {
      $status.text(text).css('color', isError ? '#f87171' : '')
    }
    const show = () => {
      const target = burrowMode.target
      $toggle.prop('checked', target.server === 'burrow')
      $server.val(target.url)
      $clients.filter(`[value="${target.client}"]`).prop('checked', true)
    }
    show()

    const describe = async url => {
      say('Checking…')
      const flashVars = await burrowMode.probe(url)
      say(`Burrow server is up: game at ${flashVars.smartfoxServer}:${flashVars.smartfoxPort}, deploy ${flashVars.deploy_version}.`)
    }

    $toggle.on('change', async () => {
      const on = $toggle.is(':checked')
      try {
        await burrowMode.setActive(on, { url: $server.val() })
        if (on) await describe(burrowMode.target.url)
        else say('')
      } catch (err) {
        say(err.message, true)
      }
      show()
    })

    $server.on('change', async () => {
      try {
        const target = await burrowMode.configure({ url: $server.val() })
        if (target.server === 'burrow') await describe(target.url)
        else say(`Saved. Burrow mode will use ${new URL(target.url).host}.`)
      } catch (err) {
        say(err.message, true)
      }
      show()
    })

    $check.on('click', async () => {
      try {
        await describe(burrowMode.normalizeUrl($server.val()))
      } catch (err) {
        say(err.message, true)
      }
    })

    $clients.on('change', async function () {
      try {
        await burrowMode.configure({ client: this.value })
      } catch (err) {
        say(err.message, true)
      }
      show()
    })

    $modal.find('[data-burrow-link]').on('click', function (event) {
      event.preventDefault()
      let url
      try {
        url = burrowMode.normalizeUrl($server.val())
      } catch (err) {
        say(err.message, true)
        return
      }
      shell.openExternal(`${url}/${this.dataset.burrowLink}`)
    })
  }
}

module.exports = BurrowSettingsManager
