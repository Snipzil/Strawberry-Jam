const { dispatch } = jam

// Avatar animation ids (AvatarWorldView.playAnim). "flip" mirrors the anim, so
// up-right becomes up-left. Ids 12, 18-21, 24-28, 30, 31 and 36 are never
// played by the client; try them with the ID box.
const GROUPS = [
  {
    title: 'Actions',
    hint: 'The emote-bar actions.',
    anims: [
      { id: 23, label: 'Dance' },
      { id: 6, label: 'Play' },
      { id: 17, label: 'Hop' },
      { id: 22, label: 'Sleep' },
      { id: 2, label: 'Sit up-right' },
      { id: 2, label: 'Sit up-left', flip: true },
      { id: 4, label: 'Sit down-right' },
      { id: 4, label: 'Sit down-left', flip: true }
    ]
  },
  {
    title: 'Water',
    hint: 'Water actions play live only in water rooms.',
    anims: [
      { id: 38, label: 'Water dance' },
      { id: 39, label: 'Water play' },
      { id: 33, label: 'Swirl' },
      { id: 41, label: 'Dive' },
      { id: 40, label: 'Water sit' },
      { id: 29, label: 'Swim' },
      { id: 32, label: 'Float idle' }
    ]
  },
  {
    title: 'Facing poses',
    hint: 'Slide-spin frames; the sits above are the diagonals.',
    anims: [
      { id: 1, label: 'Face up' },
      { id: 3, label: 'Face right' },
      { id: 3, label: 'Face left', flip: true },
      { id: 5, label: 'Face down' }
    ]
  },
  {
    title: 'Walking',
    hint: 'Walks in place.',
    anims: [
      { id: 7, label: 'Walk up' },
      { id: 8, label: 'Walk up-right' },
      { id: 9, label: 'Walk right' },
      { id: 10, label: 'Walk down-right' },
      { id: 11, label: 'Walk down' }
    ]
  },
  {
    title: 'Idle',
    anims: [
      { id: 14, label: 'Stand front' },
      { id: 16, label: 'Stand away' },
      { id: 13, label: 'Editor pose' },
      { id: 15, label: 'HUD portrait' }
    ]
  },
  {
    title: 'Hidden',
    hint: 'Minigame, quest and photo booth anims.',
    anims: [
      { id: 35, label: 'Jump in' },
      { id: 37, label: 'Idle east' },
      { id: 34, label: 'Platform jump' },
      { id: 42, label: 'Photo booth' }
    ]
  }
]

// Anims that match an action (AvatarWorldView._actionLookup), which the client
// also sends as that action so everyone in the room sees it right away.
const LIVE = new Set(['23', '22', '17', '6', '2', '2f', '4', '4f', '38', '41', '33', '39', '40', '40f'])

const groupsEl = document.getElementById('groups')
const mirror = document.getElementById('mirror')
const broadcast = document.getElementById('broadcast')
const rejoin = document.getElementById('rejoin')
const customId = document.getElementById('customId')
const statusText = document.getElementById('status')

// A room rejoin takes a few seconds; clicks during it would queue more rejoins.
const REJOIN_COOLDOWN_MS = 4000

let activeTile = null
let busyUntil = 0

function isLive(id, flip) {
  return LIVE.has(String(id) + (flip ? 'f' : ''))
}

// The patched client handles %xt%jamanim% itself; it never reaches the server.
// Broadcast 1: actions go out as the action, anything else as a hidden message
// other Strawberry Jam clients play live. Broadcast 2 also rejoins the room for
// anything that isn't an action, for players on the normal AJ client.
function playAnim(id, flip) {
  if (Date.now() < busyUntil) {
    statusText.textContent = 'Still rejoining the room, try again in a moment'
    return
  }
  const live = id !== 0 && isLive(id, flip)
  const show = broadcast.checked
  const level = !show ? 0 : (rejoin.checked && !live ? 2 : 1)
  dispatch.sendConnectionMessage(`%xt%jamanim%-1%${id}%${flip ? 1 : 0}%${level}%`)

  const label = id === 0 ? 'Normal idle' : `Playing ${id}`
  if (level === 0) {
    statusText.textContent = `${label}, only you can see it`
  } else if (live) {
    statusText.textContent = `${label}, everyone sees it`
  } else if (level === 2) {
    busyUntil = Date.now() + REJOIN_COOLDOWN_MS
    statusText.textContent = `${label}, rejoining the room for non-SJ players`
  } else {
    statusText.textContent = `${label}, Strawberry Jam players see it`
  }
}

function setActive(tile) {
  if (activeTile) activeTile.classList.remove('active')
  activeTile = tile
  if (tile) tile.classList.add('active')
}

function render() {
  for (const group of GROUPS) {
    const section = document.createElement('div')
    section.className = 'anim-section'

    const title = document.createElement('div')
    title.className = 'anim-label'
    title.textContent = group.title
    section.appendChild(title)

    if (group.hint) {
      const hint = document.createElement('div')
      hint.className = 'anim-hint'
      hint.textContent = group.hint
      section.appendChild(hint)
    }

    const grid = document.createElement('div')
    grid.className = 'anim-grid'
    for (const anim of group.anims) {
      const tile = document.createElement('button')
      tile.className = 'anim-tile'
      tile.innerHTML = `<div>${anim.label}</div><div class="anim-id">#${anim.id}${anim.flip ? ' mirrored' : ''}</div>`
      if (isLive(anim.id, !!anim.flip)) {
        const dot = document.createElement('i')
        dot.className = 'fas fa-circle anim-live'
        dot.title = 'Plays live for the room'
        tile.appendChild(dot)
      }
      tile.addEventListener('click', () => {
        setActive(tile)
        // Mirror flips whatever the tile already is.
        playAnim(anim.id, !!anim.flip !== mirror.checked)
      })
      grid.appendChild(tile)
    }
    section.appendChild(grid)
    groupsEl.appendChild(section)
  }
}

function playCustom(step) {
  let id = parseInt(customId.value, 10)
  if (isNaN(id)) id = 0
  id += step
  if (id < 1 || id > 255) return
  customId.value = id
  setActive(null)
  playAnim(id, mirror.checked)
}

document.getElementById('customBtn').addEventListener('click', () => playCustom(0))
document.getElementById('prevBtn').addEventListener('click', () => playCustom(-1))
document.getElementById('nextBtn').addEventListener('click', () => playCustom(1))
customId.addEventListener('keydown', e => {
  if (e.key === 'Enter') playCustom(0)
})

document.getElementById('resetBtn').addEventListener('click', () => {
  setActive(null)
  playAnim(0, false)
})

render()
