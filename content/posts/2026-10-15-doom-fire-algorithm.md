+++
date = '2026-10-15T16:36:54+02:00'
title = 'The Doom fire algorithm'
categories = ["Programming"]
+++

I recently stumbled over the [Doom fire algorithm](https://www.youtube.com/watch?v=6hE5sEh0pwI).
The canonical description of it is [Fabien Sanglard's blog post about the
PlayStation 1 Doom fire implementation](https://fabiensanglard.net/doom_fire_psx/).

Naturally, I wanted to play around with it and add some knobs and colour
customizations.

Here is the result. The implementation below is based on [Fabien Sanglard's
cleaned-up version](https://github.com/fabiensanglard/DoomFirePSX/blob/master/flames.html).
I kept the basic algorithm intact and added controls for the cooling and wind.
The palette is the one from the original implementation.

<style>
  #doom-fire {
    display: block;
    width: 100%;
    max-width: 100%;
    height: auto;
    background: #070707;
    image-rendering: pixelated;
  }

  #doom-fire-frame {
    position: relative;
    width: 100%;
  }

  #doom-fire-grid {
    position: absolute;
    inset: 0;
    pointer-events: none;
    background-image:
      linear-gradient(to right, rgba(255, 255, 255, 0.12) 1px, transparent 1px),
      linear-gradient(to bottom, rgba(255, 255, 255, 0.12) 1px, transparent 1px);
    background-size: calc(100% / 160) 100%, 100% calc(100% / 100);
  }

  #doom-fire-grid.is-hidden {
    display: none;
  }

  #doom-fire.is-pixelated {
    image-rendering: pixelated;
  }

  #doom-fire.is-smooth {
    image-rendering: auto;
  }

  #doom-fire-controls {
    display: flex;
    flex-direction: column;
    gap: 0.25rem;
    margin: 0.75rem 0;
  }

  .doom-fire-control {
    display: flex;
    gap: 0.75rem;
    align-items: center;
  }

  .doom-fire-control label {
    flex: 0 0 9rem;
  }

  #doom-fire-actions {
    display: flex;
    flex-wrap: wrap;
    gap: 0.5rem;
    margin-top: 0.75rem;
  }

  #doom-fire-controls input[type="range"] {
    flex: 1;
    width: 100%;
    padding: 0;
    accent-color: var(--highlight-color);
    cursor: pointer;
  }

  #doom-fire-controls input[type="range"]::-webkit-slider-runnable-track {
    accent-color: red;
  }

  #doom-fire-controls input[type="range"]::-webkit-slider-thumb {
    accent-color: green;
  }

  #doom-fire-controls output {
    min-width: 3rem;
    color: var(--color-text-muted);
    font-family: var(--font-family-secondary, monospace);
    text-align: right;
  }

  #doom-fire-actions button {
    width: 10rem;
    padding: 0.45rem 0.75rem;
    color: var(--color-inverse-text);
    font: inherit;
    font-size: 0.85em;
    background: var(--color-menu-bg);
    border: 1px solid var(--color-border);
    cursor: pointer;
    transition: background-color 0.1s linear, border-color 0.1s linear;
  }

  #doom-fire-actions button:hover,
  #doom-fire-actions button:focus-visible {
    background: var(--highlight-color);
    border-color: var(--highlight-color);
  }

  #doom-fire-actions button:focus-visible,
  #doom-fire-controls input[type="range"]:focus-visible {
    outline: 2px solid var(--highlight-color);
    outline-offset: 2px;
  }
</style>

<div id="doom-fire-frame">
  <canvas id="doom-fire" class="is-pixelated" width="160" height="100"></canvas>
  <div id="doom-fire-grid" aria-hidden="true"></div>
</div>
<div id="doom-fire-controls">
  <div class="doom-fire-control">
    <label for="doom-fire-cooling">Cooling</label>
    <output id="doom-fire-cooling-value">15%</output>
    <input id="doom-fire-cooling" type="range" min="0" max="100" step="1" value="15">
  </div>

  <div class="doom-fire-control">
    <label for="doom-fire-wind">Wind</label>
    <output id="doom-fire-wind-value">50%</output>
    <input id="doom-fire-wind" type="range" min="-100" max="100" step="1" value="50">
  </div>

  <div class="doom-fire-control">
    <label for="doom-fire-mouse-size">Mouse heat size</label>
    <output id="doom-fire-mouse-size-value">2</output>
    <input id="doom-fire-mouse-size" type="range" min="1" max="20" step="1" value="2">
  </div>

  <div class="doom-fire-control">
    <label for="doom-fire-framerate">Frame rate</label>
    <output id="doom-fire-framerate-value">25 fps</output>
    <input id="doom-fire-framerate" type="range" min="1" max="120" step="1" value="25">
  </div>
</div>
<div id="doom-fire-actions">
  <button id="doom-fire-reset" type="button">Reset</button>
  <button id="doom-fire-grid-toggle" type="button" aria-pressed="true">Hide grid</button>
  <button id="doom-fire-rendering-toggle" type="button" aria-pressed="true">Auto rendering</button>
</div>

<script src="https://cdn.jsdelivr.net/npm/easeljs@1.0.2/lib/easeljs.min.js"></script>
<script>
  (() => {
    // The canvas has a deliberately small logical resolution. CSS enlarges it
    // later, while the fire simulation continues to work with individual pixels.
    const canvas = document.querySelector("#doom-fire");
    const context = canvas.getContext("2d");
    const width = canvas.width;
    const height = canvas.height;
    let mouseSource = null;

    // Each entry contains a heat value from 0 to 36. The value is converted to
    // a colour only when the current frame is drawn.
    const pixels = new Uint8Array(width * height);
    const image = context.createImageData(width, height);

    // Keep the controls as DOM elements so their values can be changed while
    // the animation is running.
    const cooling = document.querySelector("#doom-fire-cooling");
    const wind = document.querySelector("#doom-fire-wind");
    const framerate = document.querySelector("#doom-fire-framerate");
    const mouseSize = document.querySelector("#doom-fire-mouse-size");
    const resetButton = document.querySelector("#doom-fire-reset");
    const grid = document.querySelector("#doom-fire-grid");
    const gridToggle = document.querySelector("#doom-fire-grid-toggle");
    const renderingToggle = document.querySelector("#doom-fire-rendering-toggle");

    // This is the palette from the linked Doom fire implementation. Some
    // entries intentionally occur more than once, so they are left unchanged.
    const doomPalette = [
      [0x07, 0x07, 0x07], [0x1f, 0x07, 0x07], [0x2f, 0x0f, 0x07],
      [0x47, 0x0f, 0x07], [0x57, 0x17, 0x07], [0x67, 0x1f, 0x07],
      [0x77, 0x1f, 0x07], [0x8f, 0x27, 0x07], [0x9f, 0x2f, 0x07],
      [0xaf, 0x3f, 0x07], [0xbf, 0x47, 0x07], [0xc7, 0x47, 0x07],
      [0xdf, 0x4f, 0x07], [0xdf, 0x57, 0x07], [0xdf, 0x57, 0x07],
      [0xd7, 0x5f, 0x07], [0xd7, 0x5f, 0x07], [0xd7, 0x67, 0x0f],
      [0xcf, 0x6f, 0x0f], [0xcf, 0x77, 0x0f], [0xcf, 0x7f, 0x0f],
      [0xcf, 0x87, 0x17], [0xc7, 0x87, 0x17], [0xc7, 0x8f, 0x17],
      [0xc7, 0x97, 0x1f], [0xbf, 0x9f, 0x1f], [0xbf, 0x9f, 0x1f],
      [0xbf, 0xa7, 0x27], [0xbf, 0xa7, 0x27], [0xbf, 0xaf, 0x2f],
      [0xb7, 0xaf, 0x2f], [0xb7, 0xb7, 0x2f], [0xb7, 0xb7, 0x37],
      [0xcf, 0xcf, 0x6f], [0xdf, 0xdf, 0x9f], [0xef, 0xef, 0xc7],
      [0xff, 0xff, 0xff]
    ];

    // Use the original palette from the linked Doom fire implementation.
    function palette() {
      return doomPalette;
    }

    // A white line at the bottom acts as the permanent source of heat.
    function reset() {
      pixels.fill(0);
      pixels.fill(36, (height - 1) * width);
    }

    // Convert the cursor position from the displayed canvas size to its
    // logical pixel coordinates. The canvas is responsive, so its bounding
    // rectangle can be larger than its actual 160 x 100 framebuffer.
    function updateMouseSource(event) {
      const bounds = canvas.getBoundingClientRect();
      mouseSource = {
        x: Math.floor((event.clientX - bounds.left) / bounds.width * width),
        y: Math.floor((event.clientY - bounds.top) / bounds.height * height)
      };
    }

    canvas.addEventListener("pointermove", updateMouseSource);
    canvas.addEventListener("pointerleave", () => {
      mouseSource = null;
    });

    // Move one pixel's heat upward. The random offset changes its direction,
    // while cooling controls the chance of losing one heat level.
    function spreadFire(source) {
      const heat = pixels[source];
      if (heat === 0) {
        // Empty pixels extinguish the pixel directly above them.
        pixels[source - width] = 0;
        return;
      }

      // The offset spreads heat to a neighbouring pixel. The wind control adds
      // a consistent horizontal bias to that movement.
      const offset = Math.floor(Math.random() * 4);
      const windSign = Number(wind.value) < 0 ? -1 : 1;
      const windOffset = Math.random() * 100 < Math.abs(Number(wind.value)) ? 1 : 0;
      const destination = source - width - offset + 1 + windOffset * windSign;
      const coolingOffset = Math.random() * 100 < Number(cooling.value) ? 1 : 0;
      const nextHeat = Math.max(0, heat - coolingOffset - (offset & 1));

      // Avoid writing outside the framebuffer at its left and right edges.
      if (destination >= 0 && destination < pixels.length) {
        pixels[destination] = nextHeat;
      }
    }

    function draw() {
      // The cursor is a second, temporary heat source. Its heat is injected
      // before propagation, allowing a moving cursor to leave a flame trail.
      if (mouseSource) {
        // The slider describes the diameter of a circular heat source.
        const size = Number(mouseSize.value);
        const radius = size / 2;
        const left = Math.max(0, Math.floor(mouseSource.x - radius));
        const right = Math.min(width - 1, Math.ceil(mouseSource.x + radius));
        const top = Math.max(0, Math.floor(mouseSource.y - radius));
        const bottom = Math.min(height - 1, Math.ceil(mouseSource.y + radius));

        for (let y = top; y <= bottom; y++) {
          for (let x = left; x <= right; x++) {
            const distanceX = x - mouseSource.x;
            const distanceY = y - mouseSource.y;
            if (distanceX * distanceX + distanceY * distanceY <= radius * radius) {
              pixels[y * width + x] = 36;
            }
          }
        }
      }

      // Process every row from the bottom upward. The bottom row is the heat
      // source, so it is intentionally skipped here.
      for (let x = 0; x < width; x++) {
        for (let y = 1; y < height; y++) {
          spreadFire(y * width + x);
        }
      }

      const colours = palette();
      for (let index = 0; index < pixels.length; index++) {
        // Turn the heat value into RGBA data for one canvas pixel.
        const [red, green, blue] = colours[pixels[index]];
        const target = index * 4;
        image.data[target] = red;
        image.data[target + 1] = green;
        image.data[target + 2] = blue;
        image.data[target + 3] = pixels[index] === 0 ? 0 : 255;
      }
      context.putImageData(image, 0, 0);
    }

    // Update the number displayed next to each slider as it moves.
    document.querySelectorAll("#doom-fire-controls input[type=range]").forEach((input) => {
      input.addEventListener("input", () => {
        const output = document.querySelector(`#${input.id}-value`);
        output.value = input.value;
        output.textContent = input.id === "doom-fire-framerate"
          ? `${input.value} fps`
          : input.id === "doom-fire-mouse-size"
          ? input.value
          : `${input.value}%`;

        if (input === framerate) {
          createjs.Ticker.framerate = Number(input.value);
        }
      });
    });

    // Start the simulation over with a fresh, full row of heat.
    resetButton.addEventListener("click", () => {
      reset();
      draw();
    });

    // Toggle the grid without affecting the underlying canvas or simulation.
    gridToggle.addEventListener("click", () => {
      const hidden = grid.classList.toggle("is-hidden");
      gridToggle.setAttribute("aria-pressed", String(!hidden));
      gridToggle.textContent = hidden ? "Show grid" : "Hide grid";
    });

    // Switch between crisp enlarged pixels and the browser's automatic
    // interpolation when the canvas is displayed larger than its resolution.
    renderingToggle.addEventListener("click", () => {
      const pixelated = !canvas.classList.contains("is-pixelated");
      canvas.classList.toggle("is-pixelated", pixelated);
      canvas.classList.toggle("is-smooth", !pixelated);
      renderingToggle.setAttribute("aria-pressed", String(pixelated));
      renderingToggle.textContent = pixelated ? "Auto rendering" : "Pixelated rendering";
    });

    // Seed the fire and let EaselJS call draw() at the selected frame rate.
    reset();
    createjs.Ticker.framerate = Number(framerate.value);
    createjs.Ticker.addEventListener("tick", draw);
  })();
</script>
