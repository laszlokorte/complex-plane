<script>
	import SVGCanvas from './SVGCanvas.svelte'

	const decimalFormat = new Intl.NumberFormat("en", {minimumFractionDigits:2, maximumFractionDigits:2});
	const axisFormat = new Intl.NumberFormat("en-US", {useGrouping:false, minimumSignificantDigits : 2, maximumSignificantDigits : 2,signDisplay:"auto", notation: "standard",trailingZeroDisplay:"stripIfInteger"});
	const axisFormatExp = new Intl.NumberFormat("en-US", {useGrouping:false, minimumSignificantDigits : 2, maximumSignificantDigits : 2,signDisplay:"auto", notation: "scientific"});
	let svg = null

	const draftColor = "black"

	const minZoom  = -4
	const maxZoom = 8

	let zoomFactor = 1
	$: unitScale = 100 * Math.pow(2, zoomFactor)/2


	function clamp(v, min, max) {
		return Math.max(min, Math.min(max, v))
	}

	function onWheel(evt) {
		evt.preventDefault()
		zoomFactor = clamp(zoomFactor + (-(evt.deltaY)/120/3), minZoom, maxZoom)
	}

	let inplaceEdit = true

	let colors = [
		'#e6194b', '#3cb44b', '#4363d8', '#f58231', '#911eb4', '#46f0f0', '#f032e6', '#bcf60c', '#fabebe', '#008080', '#e6beff', '#9a6324', '#fffac8', '#800000', '#aaffc3', '#808000', '#ffd8b1', '#000075', '#808080', '#ffe119', 
	].reverse()

	$: if(colors.length == 0) {
		inplaceEdit = true
	}

	function onDragStart({detail: local}) {
		if(local.target.hasAttribute('data-action')) {
			const a = local.target.getAttribute('data-action')
			if (a=='scale') {
				startScale(local)
			} else if(a=='rotate') {
				startMul(local)
			} else if(a=='translate') {
				startTranslating(local)
			} else if(a=='create') {
				startCreate(local)
			}
		} else if(local.target.hasAttribute('data-num-index')) {
			selected = 1*local.target.getAttribute('data-num-index')
		} else {
			selected = null
		}
	}
	
	function onDragEnd({detail: local}) {
		stopCreate(local)
		stopMul(local)
		stopScale(local)
		stopTranslating(local)
	}
	
	function onDragMove({detail: local}) {
		changeMul(local)
		changeCreate(local)
		changeTranslating(local)
		changeScale(local)
	}
	
	let numbers = [
	]

	function addNumber(re,im) {
		if(re==0 && im==0) {
			return
		}
		let newColor = colors.pop()

		colors = colors

		if(newColor) {
			numbers = [...numbers, {type: "lit", re: re, im: im, color: newColor}]

			return true
		}

		return false
	}


	let selected = null
	let creating = null
	let scaling = null
	let translating = null
	let rotating = null
	let snap = null

	
	addNumber(2,3)
	selected = 0

	function selectNum(evt) {
		evt.stopPropagation();
		if(!evt.currentTarget.hasAttribute("data-num-index")) {
			selected = null
		} else {
			selected = evt.currentTarget.getAttribute("data-num-index")*1
		}
	}

	function startScale(local) {
		scaling = true
	}
	
	function changeScale(local) {
		if(scaling==null) {
			return
		}

		numbers[selected] = {...numbers[selected], re: local.x/unitScale, im: -local.y/unitScale}
	}
	
	function changeTranslating(local) {
		if(translating==null) {
			return
		}
		translating = {re: local.x/unitScale, im: -local.y/unitScale}

		trySnap(translating)

		if(snap !== null) {
			translating.re = numbers[snap].re
			translating.im = numbers[snap].im
		}
	}

	function trySnap(p) {
		let i = 0;
		snap = null
		for(let n of numbers) {
			const d = Math.pow(p.re - n.re, 2) + Math.pow(p.im - n.im, 2)

			if(d<200/unitScale/unitScale) {
				snap = i
				break
			}
			i++
		}
	}
	
	function startTranslating(local) {
		translating = {re: local.x/unitScale, im: -local.y/unitScale}
	}
	
	function startMul(local) {
		rotating = true

		changeMul(local)
	}
	
	function changeMul(local) {
		if(rotating==null) {
			return
		}
		rotating = {re: local.x/unitScale, im: -local.y/unitScale}
		trySnap(rotating)
		if(snap !== null) {
			rotating.re = numbers[snap].re
			rotating.im = numbers[snap].im
		}
	}
	
	function stopMul(local) {
		if(rotating === null) {
			return
		}
		

		if(snap !== null) {

			if(!inplaceEdit) {
				copySelected()
			}

			const newRe = numbers[selected].re * numbers[snap].re - numbers[selected].im * numbers[snap].im
			const newIm = numbers[selected].im * numbers[snap].re + numbers[selected].re * numbers[snap].im
			numbers[selected].re = newRe
			numbers[selected].im = newIm
		}

		rotating = null
		snap = null
	}

	function startCreate(local) {
		creating = true
		changeCreate(local)
	}

	function changeCreate(local) {
		if(creating==null) {
			return
		}
		creating = {re: local.x/unitScale, im: -local.y/unitScale}
	}
	
	function stopCreate(local) {
		if(creating !== null && creating !== true) {
			if(addNumber(creating.re, creating.im)) {
				selected = numbers.length - 1
			}
		}
		creating = null
	}

	
	function stopScale(local) {
		scaling = null
	}
	
	function stopTranslating(local) {
		if(translating == null) {
			return
		}

		if(snap!=null) {
			if(!inplaceEdit) {
				copySelected()
			}
			numbers[selected].re += numbers[snap].re
			numbers[selected].im += numbers[snap].im
		}
		
		translating = null
		snap = null
	}

	function deleteSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		colors.push(numbers[selected].color)
		numbers = numbers.filter((e,i)=>i!==selected)
		selected = numbers.length ? numbers.length - 1 : null;

		colors = colors
	}

	function negateSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}

		numbers[selected].re *= -1
		numbers[selected].im *= -1
	}

	function conjugateSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		numbers[selected].im *= -1
	}

	function halfSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		numbers[selected].re *= 0.5
		numbers[selected].im *= 0.5
	}

	

	function projectReSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		numbers[selected].im *= 0
	}
	
	function projectImSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		numbers[selected].re *= 0
	}
	

	function rotateReSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}

		const mag = Math.hypot(numbers[selected].re, numbers[selected].im)
		numbers[selected].re = mag
		numbers[selected].im = 0
	}
	
	function rotateImSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}

		const mag = Math.hypot(numbers[selected].re, numbers[selected].im)

		numbers[selected].re = 0
		numbers[selected].im = mag
	}
	
	function rotateCCWSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}

		const newRe = -numbers[selected].im
		numbers[selected].im = numbers[selected].re
		numbers[selected].re = newRe
	}

	function squareSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		const mag = Math.hypot(numbers[selected].re, numbers[selected].im)
		let phase = Math.atan2(numbers[selected].im, numbers[selected].re)
		if(phase < 0) {
			phase +=Math.PI*2
		}
		const newMag = mag*mag
		const newPhase = phase*2

		numbers[selected].re = Math.cos(newPhase) * newMag
		numbers[selected].im = Math.sin(newPhase) * newMag
	}

	function rootSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		const mag = Math.hypot(numbers[selected].re, numbers[selected].im)
		let phase = Math.atan2(numbers[selected].im, numbers[selected].re)
		if(phase < 0) {
			phase +=Math.PI*2
		}
		const newMag = Math.sqrt(mag)
		const newPhase = phase/2

		numbers[selected].re = Math.cos(newPhase) * newMag
		numbers[selected].im = Math.sin(newPhase) * newMag
	}

	function invertSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}


		const mag = Math.hypot(numbers[selected].re, numbers[selected].im)
		let phase = Math.atan2(numbers[selected].im, numbers[selected].re)
		if(phase < 0) {
			phase +=Math.PI*2
		}
		const newMag = 1/mag
		const newPhase = -phase

		numbers[selected].re = Math.cos(newPhase) * newMag
		numbers[selected].im = Math.sin(newPhase) * newMag
	}
	
	function normalizeSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		if(!inplaceEdit) {
			copySelected()
		}

		const mag = Math.hypot(numbers[selected].re, numbers[selected].im)
		let phase = Math.atan2(numbers[selected].im, numbers[selected].re)
		if(phase < 0) {
			phase +=Math.PI*2
		}
		const newMag = 1
		const newPhase = phase

		numbers[selected].re = Math.cos(newPhase) * newMag
		numbers[selected].im = Math.sin(newPhase) * newMag
	}
	
	function copySelected() {
		if(addNumber(numbers[selected].re, numbers[selected].im)) {
			selected = numbers.length - 1
		}
	}




	function axisInterval(range) {
		var x = Math.pow(10.0, Math.floor(Math.log10(range)));
	    if (range / x >= 5)
	        return x;
	    else if (range / (x / 2.0) >= 5)
	        return x / 2.0;
	    else
	        return x / 5.0;
	}
	function segments(resolution, min, max) {
		return Array(Math.round(Math.abs(resolution))).fill(null).map((_,i,all) => min + (i/all.length)*(max-min))
	}
	function formatAxisNumber(n) {
		if(Math.abs(Math.log(Math.abs(n))) > 5) {
			return axisFormatExp.format(n).replace('E','×10^')
		} else {
			return axisFormat.format(n)
		}
	}
</script>

<style>
	.hidden {
		display: none;
	}

	.dimmed {
		opacity: 0.3;
	}
	.controls {
		position: absolute; 
		top:1em;
		left: 1em;
		gap: 0.1em;
		display: flex;
		flex-direction: column;
		z-index: 10;
		background-color: #f0f0f0ee;
		padding: 1em;
		z-index: 1000;
		max-width: 17em;
		width: 100%;
		max-height: 90%;
		overflow: auto;
		align-items: stretch;
	}

	button {
		background-color: #333;
		color: #fff;
		padding: 0.3em;
		flex-grow: 1;
		display: block;
		margin: 0;
	}

	hr {
		width: 100%;
		box-sizing: border-box;
		border: 0;
		border-bottom: 1px solid #333;
	}

	.buttons {
		gap: 0.1em; 
		padding: 0.2em;
		display: flex; 
		flex-wrap: wrap;
		flex-direction: row;
		justify-content: stretch;
		flex-grow: 1;
	}

	.buttons > button {
		flex-grow: 1;
	}

	.controls.hidden {
		display: none;
	}

	h2 {
		margin: 0;
	}

	button {
		cursor: pointer;
		margin: 0;
	}


	.container {
		position: absolute;
		inset: 0;
		display: grid;
		grid-template-columns: 1fr;
	}

	.todo::before {
		content: "✘ ";
	}

	.todo.valid::before {
		content: "✔ ";
	}

	.todo {
		color: darkred;
	}

	.valid {
		color: green;
	}
</style>

<div class="container">

	<input on:wheel|preventDefault={onWheel} style="font-size: 0.8em; margin: 0; padding: 0; position: absolute; right: 1em; bottom: 1em; z-index: 100;" type="range" bind:value={zoomFactor} min="{minZoom}" max="{maxZoom}" step="0.1">

		

	<div class="controls" class:hidden={selected==null}>
		

	{#if selected !== null}
		<h2 style="display: flex; align-items: end; gap: 0.2em">Selected:  <input style:margin="0" style:padding="0" style:width="1em" style:height="1em" type="color" bind:value={numbers[selected].color}>
<math display="inline" xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn></mrow></math>
		</h2>

		<hr>

		{@const mag = Math.hypot(numbers[selected].re, numbers[selected].im)}
		{@const phase = Math.atan2(numbers[selected].im, numbers[selected].re)}

		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>

      <mtable>
         <mtr>
         	<mtd><mn><msub><mn>z</mn>{selected}</msub></mn></mtd>
         	<mtd><mo>=</mo></mtd>
         	<mtd><mrow>{#if numbers[selected].re<0}<mo>-</mo>{/if}<mn>{decimalFormat.format(Math.abs(numbers[selected].re))}</mn><mo>{numbers[selected].im<0?'-':'+'}</mo><mn mathvariant='normal'>j</mn><mo>&InvisibleTimes;</mo><mn>{decimalFormat.format(Math.abs(numbers[selected].im))}</mn></mrow></mtd>
         	<mtd><mtext>(Cartesian)</mtext></mtd>
         </mtr>
         <mtr>
         	<mtd></mtd>
         	<mtd><mo>=</mo></mtd>
         	<mtd><mrow><mn> {decimalFormat.format(mag)}</mn><mo>&InvisibleTimes;</mo><msup><mn>e</mn><mrow><mo>{phase<0?'-':'+'}</mo><mn mathvariant='normal'>j</mn><mo>&InvisibleTimes;</mo><mn>{decimalFormat.format(Math.abs(phase/Math.PI))}</mn><mo>&InvisibleTimes;</mo><mn>&pi;</mn></mrow></msup></mrow></mtd>
         	<mtd><mtext>(Polar)</mtext></mtd>
         </mtr>
         <mtr>
         	<mtd></mtd>
         	<mtd><mo>=</mo></mtd>
         	<mtd>
         		<mrow>
         			<mo>[</mo>
				      <mtable>
				         <mtr>
				            <mtd><mn>{decimalFormat.format(numbers[selected].re)}</mn></mtd>
				            <mtd><mn>{decimalFormat.format(-numbers[selected].im)}</mn></mtd>
				         </mtr>
				         
				         <mtr>
				            <mtd><mn>{decimalFormat.format(numbers[selected].im)}</mn></mtd>
				            <mtd><mn>{decimalFormat.format(numbers[selected].re)}</mn></mtd>
				         </mtr>
				      </mtable>
				      <mo>]</mo>
         		</mrow>
         	</mtd>
         	<mtd><mtext>(Matrix)</mtext></mtd>
         </mtr>

      </mtable>
		</math>
		<br>
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mtable>
         <mtr>
         	<mtd>
				<mn>Re</mn><mo>(</mo><msub><mn>z</mn>{selected}</msub><mo>)</mo>
         	</mtd>
         	<mtd>
				<mo>=</mo>
         	</mtd>
         	<mtd>
				 <mn>{decimalFormat.format(numbers[selected].re)}</mn>
         	</mtd>
         </mtr>


         <mtr>
         	<mtd>
				<mn>Im</mn><mo>(</mo><msub><mn>z</mn>{selected}</msub><mo>)</mo>
         	</mtd>
         	<mtd>
				<mo>=</mo>
         	</mtd>
         	<mtd>
				 <mn>{decimalFormat.format(numbers[selected].im)}</mn>
         	</mtd>
         </mtr>


         <mtr>
         	<mtd>
				<mrow><mo>|</mo><msub><mn>z</mn>{selected}</msub><mo>|</mo></mrow>
         	</mtd>
         	<mtd>
				<mo>=</mo>
         	</mtd>
         	<mtd>
				 <mn>{decimalFormat.format(Math.hypot(numbers[selected].re, numbers[selected].im))}</mn>
         	</mtd>
         </mtr>


         <mtr>
         	<mtd>
				<mo>∠</mo><msub><mn>z</mn>{selected}</msub>
         	</mtd>
         	<mtd>
				<mo>=</mo>
         	</mtd>
         	<mtd>
				 <mn>{decimalFormat.format(Math.atan2(numbers[selected].im, numbers[selected].re)/Math.PI)}</mn><mo>&InvisibleTimes;</mo><mn>&pi;</mn>
         	</mtd>
         	<mtd>
				<mo>=</mo>
         	</mtd>
         	<mtd>
				<mn>{decimalFormat.format(Math.atan2(numbers[selected].im, numbers[selected].re)/Math.PI*180)}</mn><mi>°</mi>
         	</mtd>
         </mtr>

      </mtable>
		</math>

		<hr>


			<div class="buttons">
				<button type="button" on:click={deleteSelected} disabled={selected==null}>Delete</button>
			<button type="button" on:click={copySelected} disabled={selected==null || colors.length == 0}>Duplicate</button>
			</div>


		<hr>
		<div style="display: flex;">
			<label style="padding: 0.3em  0.5em 0"><input type="radio" disabled={colors.length == 0} value={true} bind:group={inplaceEdit}> Modify</label>
			<label style="padding: 0.3em  0.5em 0"><input type="radio" disabled={colors.length == 0} value={false} bind:group={inplaceEdit}> Construct</label>
		</div>
<div class="buttons">

			<button type="button" on:click={negateSelected} disabled={selected==null}>Negate</button>
			<button type="button" on:click={conjugateSelected} disabled={selected==null}>Conjugate</button>
			<button type="button" on:click={invertSelected} disabled={selected==null}>Invert</button>
		</div>
<div class="buttons">
			<button type="button" on:click={normalizeSelected} disabled={selected==null}>Normalize</button>
			<button type="button" on:click={squareSelected} disabled={selected==null}>Square</button>
			<button type="button" on:click={rootSelected} disabled={selected==null}>Square-Root</button>
			<button type="button" on:click={halfSelected} disabled={selected==null}>Divide by two</button>

		</div>
<div class="buttons">
			<button type="button" on:click={projectReSelected} disabled={selected==null}>Project onto Re</button>
			<button type="button" on:click={projectImSelected} disabled={selected==null}>Project onto Im</button>
			<button type="button" on:click={rotateReSelected} disabled={selected==null}>Rotate onto Re</button>
			<button type="button" on:click={rotateImSelected} disabled={selected==null}>Rotate onto Im</button>
			<button type="button" on:click={rotateCCWSelected} disabled={selected==null}>Rotate 90° (&sdot; i)</button>

		</div>
		<hr>
	{#if translating}
		<p style="font-size: small;" class="todo" class:valid={snap !== null}>
			Drag <svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><rect fill="white" stroke-width="3" stroke="black" x="-8" y="-8" width="16" height="16"></rect></svg> onto <svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><rect fill="white" stroke-width="3" stroke="black" x="-8" y="-8" width="16" height="16"></rect></svg> to select second operand.
		</p>
		<p>Adding
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn> <mo>+</mo><mn>{#if snap !== null}<msub><mn>z</mn>{snap}</msub>{:else}...{/if}</mn>
			</mrow>
		</math></p>
	{:else if rotating}
		<p style="font-size: small;" class="todo" class:valid={snap !== null}>
			Drag <svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><path fill="white" stroke-width="3" stroke="black" d="M-10,8H6A  8 8 0 0 0 -4 -6z"></path></svg> onto <svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><path fill="white" stroke-width="3" stroke="black" d="M-10,8H6A  8 8 0 0 0 -4 -6z"></path></svg> to select second operand.
		</p>

		<p>Multiplying
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn> <mo>&sdot;</mo><mn>{#if snap !== null}<msub><mn>z</mn>{snap}</msub>{:else}...{/if}</mn>
			</mrow>
		</math></p>
	{:else if scaling}
		<p>Modifying 
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn>
			</mrow>
		</math></p>
	{:else}
	<div style="font-size: small;">
		<p>Drag the <em>Square handle</em>(<svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><rect fill="white" stroke-width="3" stroke="black" x="-8" y="-8" width="16" height="16"></rect></svg>) to combine two Complex numbers via <em>addition</em>.</p>
		<p>Drag the <em>Wedge handle</em>(<svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><path fill="white" stroke-width="3" stroke="black" d="M-10,8H6A  8 8 0 0 0 -4 -6z"></path></svg>) to combine two Complex numbers via <em>multiplication</em>.</p>
		<p>Drag the <em>Circle handle</em>(<svg style="vertical-align: middle; width: 1em; height: 1em;" viewBox="-10 -10 20 24"><circle fill="white" stroke-width="3" stroke="black" r="8"></circle></svg>) to <em>scale and rotate</em> the Complex number.</p>

		<p style="text-align: center;">
			<a href="//tools.laszlokorte.de">More educational tools</a>
		</p>
	</div>
	{/if}
	{/if}
</div>
<SVGCanvas let:minVisible let:maxVisible on:lkdragstart={onDragStart}
on:lkdragend={onDragEnd}
on:lkdragmove={onDragMove} on:wheel={onWheel}>


	{@const arrowsize = Math.max(Math.abs(maxVisible.y - minVisible.y), Math.abs(maxVisible.x - minVisible.x)) / 220}
	{@const maxSize = Math.max(maxVisible.x, maxVisible.y)}
	{@const maxAxis = (maxSize / unitScale)}
	{@const tickWidth = axisInterval(maxAxis)}
	{@const xTickCount = Math.floor((maxVisible.x / unitScale) / tickWidth)}
	{@const yTickCount = Math.floor((maxVisible.y / unitScale) / tickWidth)}
	{@const xTickLength = xTickCount * tickWidth * unitScale}
	{@const yTickLength = yTickCount * tickWidth * unitScale}

	<g>
		<path vector-effect="non-scaling-stroke" d={segments(xTickCount, 0, xTickLength).slice(1).map((x) => `M${x} ${-arrowsize} V${arrowsize} `).join("")} stroke="black"/>
		<path vector-effect="non-scaling-stroke" d={segments(xTickCount, 0, -xTickLength).slice(1).map((x) => `M${x} ${-arrowsize} V${arrowsize} `).join("")} stroke="black"/>
		<path vector-effect="non-scaling-stroke" d={segments(yTickCount, 0, yTickLength).slice(1).map((x) => `M${-arrowsize} ${x} H${arrowsize} `).join("")} stroke="black"/>
		<path vector-effect="non-scaling-stroke" d={segments(yTickCount, 0, -yTickLength).slice(1).map((x) => `M${-arrowsize} ${x} H${arrowsize} `).join("")} stroke="black"/>
		{#each segments(xTickCount, 0, xTickLength).slice(1) as s, si}
			{#if !si || si%2 == 1}
			<text x="{s}" y="{arrowsize*4}" font-size={arrowsize*2} text-anchor="middle">{formatAxisNumber(s/unitScale)}</text>
			{/if}
		{/each}
		{#each segments(xTickCount, 0, -xTickLength).slice(1) as s, si}
			{#if !si || si%2 == 1}
			<text x="{s}" y="{arrowsize*4}" font-size={arrowsize*2} text-anchor="middle">{formatAxisNumber(s/unitScale)}</text>
			{/if}
		{/each}
		{#each segments(yTickCount, 0, -yTickLength).slice(1) as s, si}
			{#if !si || si%2 == 1}
			<text y="{s}" x="{-arrowsize*3}" font-size={arrowsize*2} text-anchor="end" dominant-baseline="middle">{formatAxisNumber(-s/unitScale)}j</text>
			{/if}
		{/each}
		{#each segments(yTickCount, 0, yTickLength).slice(1) as s, si}
			{#if !si || si%2 == 1}
			<text y="{s}" x="{-arrowsize*3}" font-size={arrowsize*2} text-anchor="end" dominant-baseline="middle">{formatAxisNumber(-s/unitScale)}j</text>
			{/if}
		{/each}
	</g>

	<path d="M{minVisible.x+50},0H{maxVisible.x-50}M0,{minVisible.y+50}V{maxVisible.y-50}" stroke="black"/>
	<path fill="black" d="M0,{minVisible.y+50}l-5,10h10z"></path>
	<path fill="black" d="M{maxVisible.x-50},0l-10,-5v10z"></path>

	<g>
		{#if selected !== null}
		{@const num = numbers[selected]}
		{@const mag = Math.hypot(num.re, num.im)}
		{@const phase = Math.atan2(num.im, num.re)}
			<line  class:hidden={translating||rotating} stroke-linecap="round" x1="0" y1="0" x2={num.re*unitScale} y2={-num.im*unitScale} stroke="lightblue" stroke-width="10" />
			<path class:hidden={scaling||translating||rotating}  d="M0,0m-8,-8v16h16v-16h-16" fill="none" stroke="lightblue" stroke-width="10"></path>
			<circle class:hidden={translating||rotating}  cx={num.re*unitScale} cy={-num.im*unitScale} r="10" stroke="lightblue" stroke-width="10"></circle>

			<path  class:hidden={translating||rotating} d="M0,{-num.im*unitScale}H{num.re*unitScale}M{num.re*unitScale},0V{-num.im*unitScale}" fill="none" stroke="{num.color}" stroke-opacity="0.4" stroke-width="2" stroke-dasharray="5 5"></path>
			<path  class:hidden={translating||rotating} d="M{unitScale},0A {unitScale} {unitScale} 0 0 {num.im<0?1:0} {num.re/mag*unitScale} {-num.im/mag*unitScale}" fill="none" stroke-opacity="0.4" fill-opacity="0.3" stroke="{num.color}" stroke-width="2" stroke-dasharray="5 5"></path>
			<path  class:hidden={translating||rotating} d="M0,0H{unitScale}A {unitScale} {unitScale} 0 0 {num.im<0?1:0} {num.re/mag*unitScale} {-num.im/mag*unitScale}" fill="{num.color}" fill-opacity="0.2"></path>
			
			<text font-size={arrowsize*2} class:hidden={translating||rotating} x="{num.re>0?-10:10}" y="{-num.im*unitScale+5}" text-anchor="{num.re>0?"end":"start"}">{decimalFormat.format(num.im)}</text>
			<text font-size={arrowsize*2} class:hidden={translating||rotating} y="{num.im>0?30:-20}" x="{num.re*unitScale}" text-anchor="middle">{decimalFormat.format(num.re)}</text>
			<text font-size={arrowsize*2} class:hidden={translating||rotating} y="{-num.im*unitScale/2}" x="{num.re*unitScale/2+(num.im>0!==num.re>0?10:-10)}" text-anchor="{num.im>0!==num.re>0?"start":"end"}">{decimalFormat.format(mag)}</text>
			<text font-size={arrowsize*2} class:hidden={translating||rotating} y="{-Math.sin(phase/2)*unitScale*0.65+5}" x="{Math.cos(phase/2)*unitScale*0.65}" text-anchor="middle">{decimalFormat.format(phase/Math.PI)}&pi;</text>
		{/if}
	</g>
	
	{#each numbers as num, ni}
		{@const mag = Math.hypot(num.re, num.im)}
		{@const phase = Math.atan2(num.im, num.re)}
		<line class:dimmed={(rotating||translating) && ni==selected} stroke-linecap="round" x1="0" y1="0" x2={num.re*unitScale} y2={-num.im*unitScale} stroke={num.color} stroke-width="3" />
		<polygon class:dimmed={(rotating||translating) && ni==selected}  points="-12 10 -12 -10 3 0" transform="rotate({-phase*180/Math.PI}) translate({unitScale*mag}, 0)" fill={num.color} />
	{/each}	

	
	{#each numbers as num, ni}
		{@const mag = Math.hypot(num.re, num.im)}
		{@const phase = Math.atan2(num.im, num.re)}
		<g on:keydown={selectNum} tabindex="0" role="button" data-num-index={ni} pointer-events="all">
		<line stroke-linecap="round" x1="0" y1="0"  data-num-index={ni} x2={num.re*unitScale} y2={-num.im*unitScale} stroke="none"  stroke-width="20" pointer-events="all" />
		<polygon points="-12 10 -12 -10 3 0"  data-num-index={ni} transform="rotate({-phase*180/Math.PI}) translate({unitScale*mag}, 0)" fill="none" pointer-events="all" />
		</g>
	{/each}

	{#if selected === null && (creating == null || creating == true)}
		{#if colors.length > 0}
		<circle data-action="create" cursor="move" cx="{clamp(unitScale, 50, 300)}" cy="0" r="10" fill="black" stroke="black"></circle>
		<path pointer-events="none" d="M{clamp(unitScale, 50, 300)},0m-6,0h12M{clamp(unitScale, 50, 300)},0m0,-6v12" stroke="white" stroke-width="2"></path>
		{/if}


		{#each numbers as num, ni}
			<foreignObject pointer-events="none" xmlns="http://www.w3.org/2000/svg"  xmlns:math="http://www.w3.org/1998/Math/MathML" width="30" height="30" x={num.re*unitScale + Math.sign(num.re)*10 - 15} y={-num.im*unitScale - 15 - Math.sign(num.im)*10}>
				<math:math xmlns="http://www.w3.org/1998/Math/MathML" pointer-events="all"  data-num-index={ni} style:font-size="1.2em">
					<math:mrow><math:msub><math:mn>z</math:mn><math:mn>{ni}</math:mn></math:msub></math:mrow>
				</math:math>
			</foreignObject>	
		{/each}	

	{/if}

	
	{#if creating !== null && creating !== true}
		{@const num = creating}
		{@const mag = Math.hypot(num.re, num.im)}

		<path  d="M0,{-num.im*unitScale}H{num.re*unitScale}M{num.re*unitScale},0V{-num.im*unitScale}" fill="none" stroke={draftColor} stroke-width="2" stroke-dasharray="5 5"></path>
		<path  d="M{unitScale},0A {unitScale} {unitScale} 0 0 {num.im<0?1:0} {num.re/mag*unitScale} {-num.im/mag*unitScale}" fill="none" fill-opacity="0.2" stroke={draftColor} stroke-width="2" stroke-dasharray="5 5"></path>
		<path  d="M0,0H{unitScale}A {unitScale} {unitScale} 0 0 {num.im<0?1:0} {num.re/mag*unitScale} {-num.im/mag*unitScale}" fill={draftColor} fill-opacity="0.2"></path>
		
		<line stroke-linecap="round" x1="0" y1="0" x2={num.re*unitScale} y2={-num.im*unitScale} stroke={draftColor} stroke-width="4" />
		
		<circle cx={num.re*unitScale} cy={-num.im*unitScale} r="10" fill="black" stroke="black"></circle>
		<path pointer-events="none" d="M{num.re*unitScale},{-num.im*unitScale}m-6,0h12m-6,-6v12" stroke="white" stroke-width="2"></path>
	{/if}

	{#if selected !== null}
		{@const num = numbers[selected]}
		{@const mag = Math.hypot(num.re, num.im)}		
		<path  d="M0,0H{unitScale}A {unitScale} {unitScale} 0 0 {num.im<0?1:0} {num.re/mag*unitScale} {-num.im/mag*unitScale}" fill="none" pointer-events="none"></path>
		<path  data-action="rotate" stroke-linejoin="round" class:hidden={scaling||translating||rotating} cursor="move" d="M{unitScale-10},4h24a 16 16 0 0 0 -10 -18z" stroke="{num.color}" fill="white" stroke-width="3"></path>
		<path  data-action="translate" class:hidden={scaling||translating||rotating} cursor="move" d="M0,0m-8,-8v16h16v-16h-16" stroke="{num.color}" fill="white" stroke-width="3"></path>
		<circle  data-action="scale" class:hidden={translating||rotating} cursor="move" cx={num.re*unitScale} cy={-num.im*unitScale} r="10" stroke="{num.color}" fill="white" stroke-width="3"></circle>

	{/if}

	{#if translating !== null && selected !== null}
			{#each numbers as num, ni}
				<path d="M{num.re*unitScale},{-num.im*unitScale}m-8,-8v16h16v-16h-16" stroke="{num.color}" fill="white" stroke-width="{snap==ni?10:3}"></path>
			{/each}
		
		{@const num = numbers[selected]}
		{@const newmag = Math.hypot((num.re+translating.re), (num.im+translating.im))}
		{@const newphase = Math.atan2((num.im+translating.im), (num.re+translating.re))}
		<line stroke-linecap="round" x1={0} y1={0}  x2={(num.re+translating.re)*unitScale} y2={-(num.im+translating.im)*unitScale} stroke="lightblue" stroke-width="10" />
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-newphase*180/Math.PI}) translate({unitScale*newmag}, 0)" fill="none" stroke="lightblue" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"  />

		<line stroke-linecap="round" stroke-linejoin="round"  x1={0} y1={0} x2={(num.re+translating.re)*unitScale} y2={-(num.im+translating.im)*unitScale} stroke="{num.color}" stroke-width="3" />
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-newphase*180/Math.PI}) translate({unitScale*newmag}, 0)" fill={num.color} />

		
		<line class="hidden" stroke-linecap="round" stroke-linejoin="round"  x1={(translating.re)*unitScale} y1={-(translating.im)*unitScale}  x2={(num.re+translating.re)*unitScale} y2={-(num.im+translating.im)*unitScale} stroke="lightblue" stroke-width="10" />
		<path d="M{translating.re*unitScale},{-translating.im*unitScale}0m-8,-8v16h16v-16h-16" fill="none" stroke="lightblue" stroke-width="10"></path>

		<line stroke-linecap="round" stroke-linejoin="round"  x1={(num.re)*unitScale} y1={-(num.im)*unitScale}  x2={(num.re+translating.re)*unitScale} y2={-(num.im+translating.im)*unitScale} stroke-dasharray="3 8" stroke="gray" stroke-width="2" />
		<line stroke-linecap="round" stroke-linejoin="round"  x1={0} y1={0}  x2={(translating.re)*unitScale} y2={-(translating.im)*unitScale} stroke-dasharray="3 8" stroke="gray" stroke-width="2" />
		


		<polygon points="-10 8 -10 -8 3 0" transform="translate({(num.re+translating.re*0.8)*unitScale}, {-(num.im+translating.im*0.8)*unitScale} ) rotate({Math.atan2(-translating.im, translating.re)/Math.PI*180})" fill="gray" />
		<polygon points="-10 8 -10 -8 3 0" transform="translate({(translating.re)*unitScale*0.8}, {-(translating.im)*unitScale*0.8} ) rotate({Math.atan2(-translating.im, translating.re)/Math.PI*180})" fill="gray" />


		<path cursor="move" d="M{translating.re*unitScale},{-translating.im*unitScale}m-8,-8v16h16v-16h-16" stroke="{num.color}" fill="white" stroke-width="3"></path>
	
	{/if}

	{#if rotating !== null && selected !== null}
		
			{#each numbers as num, ni}
				<path stroke-linejoin="round" d="M{num.re*unitScale},{-num.im*unitScale}m-15,10h24a 16 16 0 0 0 -10 -18z" stroke="{num.color}" fill="white" stroke-width={snap==ni?10:3}></path>
			{/each}
		
		{@const num = numbers[selected]}
		{@const nummag = Math.hypot(num.re, num.im)}
		{@const numphase = Math.atan2(num.im, num.re)}
		{@const mag = Math.hypot(rotating.re, rotating.im)}		
		{@const phase = Math.atan2(rotating.im, rotating.re)}

		<path d="M{rotating.re*unitScale} {-rotating.im*unitScale}M{unitScale},0A {unitScale} {unitScale} 0 0 {rotating.im<0?1:0} {rotating.re/mag*unitScale} {-rotating.im/mag*unitScale}"  fill="none" stroke-dasharray="5 5" stroke="gray" stroke-width="3" fill-opacity="0.2"></path>
		<path d="M {num.re*unitScale/nummag*mag} {-num.im*unitScale/nummag*mag}A {unitScale*mag} {unitScale*mag} 0 0 {rotating.im<0?1:0} {Math.cos(numphase+phase)*unitScale*mag} {-Math.sin(numphase+phase)*unitScale*mag}"  fill="none" stroke-dasharray="5 5" stroke="gray" stroke-width="3" fill-opacity="0.2"></path>
		

		<path d="M0,0L{unitScale},0L{(num.re)*unitScale},{-(num.im)*unitScale}" fill="{num.color}" fill-opacity="0.05" stroke={num.color} stroke-opacity="0.4"></path>
		<path d="M0,0L{Math.cos(phase)*(mag)*unitScale},{-Math.sin(phase)*(mag)*unitScale}L{Math.cos(numphase+phase)*(nummag*mag)*unitScale},{-Math.sin(numphase+phase)*(nummag*mag)*unitScale}" fill="{num.color}" fill-opacity="0.05" stroke={num.color} stroke-opacity="0.4"></path>
		<path d="M0,0L{Math.cos(numphase+phase)*(nummag*mag)*unitScale},{-Math.sin(numphase+phase)*(nummag*mag)*unitScale}" stroke="lightblue" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" ></path>
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-(numphase+phase)*180/Math.PI}) translate({unitScale*nummag*mag}, 0)" fill="none" stroke="lightblue" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"  />


		<path d="M0,0L{Math.cos(numphase+phase)*(nummag*mag)*unitScale},{-Math.sin(numphase+phase)*(nummag*mag)*unitScale}" stroke="{num.color}" stroke-width="3"></path>
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-(numphase+phase)*180/Math.PI}) translate({unitScale*nummag*mag}, 0)" fill={num.color} />

		<path stroke-linejoin="round" pointer-events="none" d="M{rotating.re*unitScale},{-rotating.im*unitScale}m-15,10h24a 16 16 0 0 0 -10 -18z" stroke="{num.color}" fill="white" stroke-width="3"></path>
	{/if}

	<g>
		
	<text font-size={arrowsize*2}  x="{maxVisible.x- 60}" y="-10" text-anchor="end">Re</text>
	<text  font-size={arrowsize*2} x="10" y="{-maxVisible.y + 60}" text-anchor="start">Im</text>
	</g>
</SVGCanvas>
</div>