<script>
	const decimalFormat = new Intl.NumberFormat("en", {minimumFractionDigits:2, maximumFractionDigits:2});
	let svg = null
	$: svgPoint = svg ? svg.createSVGPoint() : null;

	let colors = ["red","green", "blue", "orange", "magenta", "cyan", "purple"].reverse()

	$: svgCoords = (evt) => {
	    svgPoint.x = evt.clientX;
	    svgPoint.y = evt.clientY;

			const res = svgPoint.matrixTransform(svg.getScreenCTM().inverse())
		
			return {x: res.x/100, y: -res.y/100}
	}
	
	let numbers = [
	]

	function addNumber(re,im) {
		if(re==0 && im==0) {
			return
		}
		let newColor = colors.pop()
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

	function startScale(evt) {
		evt.stopPropagation();
		scaling = true
	}
	
	function changeScale(evt) {
		if(scaling==null) {
			return
		}
		const p = svgCoords(evt);
		numbers[selected] = {...numbers[selected], re: p.x, im: p.y}
	}
	
	function changeTranslating(evt) {
		if(translating==null) {
			return
		}
		const p = svgCoords(evt);
		translating = {re: p.x, im: p.y}

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

			if(d<0.02) {
				snap = i
				break
			}
			i++
		}
	}
	
	function startTranslating(evt) {
		evt.stopPropagation();
		const p = svgCoords(evt);
		translating = {re: p.x, im: p.y}
	}
	
	function startMul(evt) {
		evt.stopPropagation();

		rotating = true
	}
	
	function changeMul(evt) {
		if(rotating==null) {
			return
		}
		const p = svgCoords(evt);
		rotating = {re: p.x, im: p.y}
		trySnap(rotating)
		if(snap !== null) {
			rotating.re = numbers[snap].re
			rotating.im = numbers[snap].im
		}
	}
	
	function stopMul(evt) {
		if(rotating === null) {
			return
		}
		
		evt.stopPropagation();

		if(snap !== null) {
			const newRe = numbers[selected].re * numbers[snap].re - numbers[selected].im * numbers[snap].im
			const newIm = numbers[selected].im * numbers[snap].re + numbers[selected].re * numbers[snap].im
			numbers[selected].re = newRe
			numbers[selected].im = newIm
		}

		rotating = null
		snap = null
	}

	function startCreate(evt) {
		evt.stopPropagation();
		creating = true
		changeCreate(evt)
	}

	function changeCreate(evt) {
		if(creating==null) {
			return
		}
		const p = svgCoords(evt);
		creating = {re: p.x, im: p.y}
	}
	
	function stopCreate(evt) {
		if(creating !== null && creating !== true) {
			if(addNumber(creating.re, creating.im)) {
				selected = numbers.length - 1
			}
		}
		creating = null
	}

	
	function stopScale(evt) {
		scaling = null
	}
	
	function stopTranslating(evt) {
		if(translating == null) {
			return
		}

		if(snap!=null) {
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
	}

	function negateSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		numbers[selected].re *= -1
		numbers[selected].im *= -1
	}

	function conjugateSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		numbers[selected].im *= -1
	}

	function halfSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		numbers[selected].re *= 0.5
		numbers[selected].im *= 0.5
	}

	

	function projectReSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		numbers[selected].im *= 0
	}
	
	function projectImSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		numbers[selected].re *= 0
	}
	

	function rotateReSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}
		const mag = Math.sqrt(numbers[selected].re*numbers[selected].re + numbers[selected].im*numbers[selected].im)
		numbers[selected].re = mag
		numbers[selected].im = 0
	}
	
	function rotateImSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}
		const mag = Math.sqrt(numbers[selected].re*numbers[selected].re + numbers[selected].im*numbers[selected].im)

		numbers[selected].re = 0
		numbers[selected].im = mag
	}

	function squareSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		const newRe = numbers[selected].re*numbers[selected].re - numbers[selected].im*numbers[selected].im
		const newIm = 2*numbers[selected].re*numbers[selected].im
		numbers[selected].re = newRe
		numbers[selected].im = newIm
	}

	function rootSelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}

		const mag = Math.sqrt(numbers[selected].re*numbers[selected].re + numbers[selected].im*numbers[selected].im)
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

		const mag = Math.sqrt(numbers[selected].re*numbers[selected].re + numbers[selected].im*numbers[selected].im)
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

		const mag = Math.sqrt(numbers[selected].re*numbers[selected].re + numbers[selected].im*numbers[selected].im)
		let phase = Math.atan2(numbers[selected].im, numbers[selected].re)
		if(phase < 0) {
			phase +=Math.PI*2
		}
		const newMag = 1
		const newPhase = phase

		numbers[selected].re = Math.cos(newPhase) * newMag
		numbers[selected].im = Math.sin(newPhase) * newMag
	}
	
	function copySelected(evt) {
		if(evt.currentTarget.disabled) {
			return
		}
		if(addNumber(numbers[selected].re, numbers[selected].im)) {
			selected = numbers.length - 1
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

	svg {
		position: absolute;
		inset: 0;
		width: 100%;
		height: 100%;
	}

	.controls {
		position: absolute; 
		top:1em; 
		gap: 1em;
		display: flex;
		z-index: 10;
	}

	.buttons {
		gap: 0.1em; 
		padding: 0.2em;
		display: flex; 
		flex-direction: column;
		background-color: #0002;
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
</style>

<svelte:window on:pointerup={stopCreate} on:pointerup={stopScale} on:pointerup={stopTranslating} on:pointerup={stopMul} on:pointermove={changeMul} on:pointermove={changeCreate} on:pointermove={changeScale} on:pointermove={changeTranslating} />
<div style="padding-top: 3em">
	<div class="controls" class:hidden={selected==null}>
		
		<div class="buttons">
			<button type="button" on:click={deleteSelected} disabled={selected==null}>Delete</button>
			<button type="button" on:click={negateSelected} disabled={selected==null}>Negate</button>
			<button type="button" on:click={conjugateSelected} disabled={selected==null}>Conjugate</button>
			<button type="button" on:click={halfSelected} disabled={selected==null}>&sdot;0.5</button>
			<button type="button" on:click={squareSelected} disabled={selected==null}>Square</button>
			<button type="button" on:click={rootSelected} disabled={selected==null}>Root</button>
			<button type="button" on:click={invertSelected} disabled={selected==null}>Invert</button>
			<button type="button" on:click={normalizeSelected} disabled={selected==null}>Normalize</button>
			<button type="button" on:click={copySelected} disabled={selected==null}>Copy</button>
			<button type="button" on:click={projectReSelected} disabled={selected==null}>Project Real</button>
			<button type="button" on:click={projectImSelected} disabled={selected==null}>Project Imaginary</button>
			<button type="button" on:click={rotateReSelected} disabled={selected==null}>Rotate Real</button>
			<button type="button" on:click={rotateImSelected} disabled={selected==null}>Rotate Imaginary</button>

		</div>
		<div>
	{#if selected !== null}
		<h2>Selected: <math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn></mrow></math></h2>

		{@const mag = Math.sqrt(numbers[selected].re*numbers[selected].re + numbers[selected].im*numbers[selected].im)}
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
         	<mtd><mrow><mn> {decimalFormat.format(mag)}</mn><mo>&sdot;</mo><msup><mn>e</mn><mrow><mo>{phase<0?'-':'+'}</mo><mn mathvariant='normal'>j</mn><mo>&InvisibleTimes;</mo><mn>{decimalFormat.format(Math.abs(phase/Math.PI))}</mn><mo>&InvisibleTimes;</mo><mn>&pi;</mn></mrow></msup></mrow></mtd>
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
	{#if translating}
		<p>Adding
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn> <mo>+</mo><mn>{#if snap !== null}<msub><mn>z</mn>{snap}</msub>{:else}...{/if}</mn>
			</mrow>
		</math></p>
	{/if}
	{#if rotating}
		<p>Multiplying
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn> <mo>&sdot;</mo><mn>{#if snap !== null}<msub><mn>z</mn>{snap}</msub>{:else}...{/if}</mn>
			</mrow>
		</math></p>
	{/if}
	{#if scaling}
		<p>Modifying 
		<math xmlns = "http://www.w3.org/1998/Math/MathML">
			<mrow>
		<mn><msub><mn>z</mn>{selected}</msub></mn>
			</mrow>
		</math></p>
	{/if}
	{/if}
</div>
</div>

<svg style="user-select: none;" cursor={creating!==null?"move":"default"} bind:this={svg} viewBox="-500 -500 1000 1000" on:keydown={selectNum} tabindex="0" role="button" on:pointerdown={selectNum}>
	<path d="M-500,0H500M0,-500V500" stroke="black"/>
	<path fill="black" d="M0-500l-5,10h10z"></path>
	<path fill="black" d="M500,0l-10,-5v10z"></path>

	<g>
		{#if selected !== null}
		{@const num = numbers[selected]}
		{@const mag = Math.sqrt(num.re*num.re + num.im*num.im)}
		{@const phase = Math.atan2(num.im, num.re)}
			<line  class:hidden={translating||rotating} stroke-linecap="round" x1="0" y1="0" x2={num.re*100} y2={-num.im*100} stroke="lightblue" stroke-width="10" />
			<path class:hidden={scaling||translating||rotating}  d="M0,0m-8,-8v16h16v-16h-16" fill="none" stroke="lightblue" stroke-width="10"></path>
			<circle class:hidden={translating||rotating}  cx={num.re*100} cy={-num.im*100} r="10" stroke="lightblue" stroke-width="10"></circle>

			<path  class:hidden={translating||rotating} d="M0,{-num.im*100}H{num.re*100}M{num.re*100},0V{-num.im*100}" fill="none" stroke="{num.color}" stroke-opacity="0.4" stroke-width="2" stroke-dasharray="5 5"></path>
			<path  class:hidden={translating||rotating} d="M100,0A 100 100 0 0 {num.im<0?1:0} {num.re/mag*100} {-num.im/mag*100}" fill="none" stroke-opacity="0.4" fill-opacity="0.3" stroke="{num.color}" stroke-width="2" stroke-dasharray="5 5"></path>
			<path  class:hidden={translating||rotating} d="M0,0H100A 100 100 0 0 {num.im<0?1:0} {num.re/mag*100} {-num.im/mag*100}" fill="{num.color}" fill-opacity="0.2"></path>
			
			<text  class:hidden={translating||rotating} x="{num.re>0?-10:10}" y="{-num.im*100+5}" text-anchor="{num.re>0?"end":"start"}">{decimalFormat.format(num.im)}</text>
			<text  class:hidden={translating||rotating} y="{num.im>0?30:-20}" x="{num.re*100}" text-anchor="middle">{decimalFormat.format(num.re)}</text>
			<text  class:hidden={translating||rotating} y="{-num.im*100/2}" x="{num.re*100/2+(num.im>0!==num.re>0?10:-10)}" text-anchor="{num.im>0!==num.re>0?"start":"end"}">{decimalFormat.format(mag)}</text>
			<text  class:hidden={translating||rotating} y="{-Math.sin(phase/2)*50}" x="{Math.cos(phase/2)*50}" text-anchor="middle">{decimalFormat.format(phase/Math.PI)}&pi;</text>
		{/if}
	</g>
	
	{#each numbers as num, ni}
		{@const mag = Math.sqrt(num.re*num.re + num.im*num.im)}
		{@const phase = Math.atan2(num.im, num.re)}
		<line class:dimmed={(rotating||translating) && ni==selected} stroke-linecap="round" x1="0" y1="0" x2={num.re*100} y2={-num.im*100} stroke={num.color} stroke-width="3" />
		<polygon class:dimmed={(rotating||translating) && ni==selected}  points="-12 10 -12 -10 3 0" transform="rotate({-phase*180/Math.PI}) translate({100*mag}, 0)" fill={num.color} />
	{/each}	

	
	{#each numbers as num, ni}
		{@const mag = Math.sqrt(num.re*num.re + num.im*num.im)}
		{@const phase = Math.atan2(num.im, num.re)}
		<g on:keydown={selectNum} tabindex="0" role="button" data-num-index={ni} on:pointerdown={selectNum} pointer-events="all">
		<line stroke-linecap="round" x1="0" y1="0" x2={num.re*100} y2={-num.im*100} stroke="none"  stroke-width="10" />
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-phase*180/Math.PI}) translate({100*mag}, 0)" fill="none" />
		</g>
	{/each}

	{#if selected === null && (creating == null || creating == true) && colors.length}
		<circle cursor="move" on:pointerdown={startCreate} cx="100" cy="0" r="10" fill="black" stroke="black"></circle>
		<path pointer-events="none" d="M100,0m-6,0h12M100,0m0,-6v12" stroke="white" stroke-width="2"></path>


	{#each numbers as num, ni}
		<foreignObject pointer-events="none" width="30" height="30" x={num.re*100 + Math.sign(num.re)*10 - 15} y={-num.im*100 - 15 - Math.sign(num.im)*10} requiredExtensions="http://www.w3.org/1998/Math/MathML">
			<math style:font-size="1.2em" xmlns="http://www.w3.org/1998/Math/MathML" display="block">
				<mrow><msub><mn>z</mn><mn>{ni}</mn></msub></mrow>
			</math>
		</foreignObject>	
	{/each}	

	{/if}

	
	{#if creating !== null && creating !== true}
		{@const num = creating}
		{@const mag = Math.sqrt(num.re*num.re + num.im*num.im)}

		<path  d="M0,{-num.im*100}H{num.re*100}M{num.re*100},0V{-num.im*100}" fill="none" stroke="lightgreen" stroke-width="2" stroke-dasharray="5 5"></path>
		<path  d="M100,0A 100 100 0 0 {num.im<0?1:0} {num.re/mag*100} {-num.im/mag*100}" fill="none" fill-opacity="0.2" stroke="lightgreen" stroke-width="2" stroke-dasharray="5 5"></path>
		<path  d="M0,0H100A 100 100 0 0 {num.im<0?1:0} {num.re/mag*100} {-num.im/mag*100}" fill="lightgreen" fill-opacity="0.2"></path>
		
		<line stroke-linecap="round" x1="0" y1="0" x2={num.re*100} y2={-num.im*100} stroke="lightgreen" stroke-width="4" />
		
		<circle on:pointerdown={startCreate} cx={num.re*100} cy={-num.im*100} r="10" fill="black" stroke="black"></circle>
		<path pointer-events="none" d="M{num.re*100},{-num.im*100}m-6,0h12m-6,-6v12" stroke="white" stroke-width="2"></path>
	{/if}

	{#if selected !== null}
		{@const num = numbers[selected]}
		{@const mag = Math.sqrt(num.re*num.re + num.im*num.im)}		
		<path  d="M0,0H100A 100 100 0 0 {num.im<0?1:0} {num.re/mag*100} {-num.im/mag*100}" fill="none" pointer-events="none"></path>
		<path stroke-linejoin="round" class:hidden={scaling||translating||rotating} on:pointerdown={startMul} cursor="move" d="M90,4h24a 16 16 0 0 0 -10 -18z" stroke="{num.color}" fill="white" stroke-width="3"></path>
		<path class:hidden={scaling||translating||rotating} on:pointerdown={startTranslating} cursor="move" d="M0,0m-8,-8v16h16v-16h-16" stroke="{num.color}" fill="white" stroke-width="3"></path>
		<circle class:hidden={translating||rotating} on:pointerdown={startScale} cursor="move" cx={num.re*100} cy={-num.im*100} r="10" stroke="{num.color}" fill="white" stroke-width="3"></circle>

	{/if}

	{#if translating !== null && selected !== null}
			{#each numbers as num, ni}
				<path d="M{num.re*100},{-num.im*100}m-8,-8v16h16v-16h-16" stroke="{num.color}" fill="white" stroke-width="{snap==ni?10:3}"></path>
			{/each}
		
		{@const num = numbers[selected]}
		{@const newmag = Math.hypot((num.re+translating.re), (num.im+translating.im))}
		{@const newphase = Math.atan2((num.im+translating.im), (num.re+translating.re))}
		<line stroke-linecap="round" x1={0} y1={0}  x2={(num.re+translating.re)*100} y2={-(num.im+translating.im)*100} stroke="lightblue" stroke-width="10" />
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-newphase*180/Math.PI}) translate({100*newmag}, 0)" fill="none" stroke="lightblue" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"  />

		<line stroke-linecap="round" stroke-linejoin="round"  x1={0} y1={0} x2={(num.re+translating.re)*100} y2={-(num.im+translating.im)*100} stroke="{num.color}" stroke-width="3" />
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-newphase*180/Math.PI}) translate({100*newmag}, 0)" fill={num.color} />

		
		<line class="hidden" stroke-linecap="round" stroke-linejoin="round"  x1={(translating.re)*100} y1={-(translating.im)*100}  x2={(num.re+translating.re)*100} y2={-(num.im+translating.im)*100} stroke="lightblue" stroke-width="10" />
		<path d="M{translating.re*100},{-translating.im*100}0m-8,-8v16h16v-16h-16" fill="none" stroke="lightblue" stroke-width="10"></path>

		<line stroke-linecap="round" stroke-linejoin="round"  x1={(num.re)*100} y1={-(num.im)*100}  x2={(num.re+translating.re)*100} y2={-(num.im+translating.im)*100} stroke-dasharray="5 5" stroke="gray" stroke-width="2" />
		<line stroke-linecap="round" stroke-linejoin="round"  x1={0} y1={0}  x2={(translating.re)*100} y2={-(translating.im)*100} stroke-dasharray="5 5" stroke="gray" stroke-width="2" />
		<path on:pointerdown={startTranslating} cursor="move" d="M{translating.re*100},{-translating.im*100}m-8,-8v16h16v-16h-16" stroke="{num.color}" fill="white" stroke-width="3"></path>
	
	{/if}

	{#if rotating !== null && selected !== null}
		
			{#each numbers as num, ni}
				<path stroke-linejoin="round" d="M{num.re*100},{-num.im*100}m-15,10h24a 16 16 0 0 0 -10 -18z" stroke="{num.color}" fill="white" stroke-width={snap==ni?10:3}></path>
			{/each}
		
		{@const num = numbers[selected]}
		{@const nummag = Math.sqrt(num.re*num.re + num.im*num.im)}
		{@const numphase = Math.atan2(num.im, num.re)}
		{@const mag = Math.sqrt(rotating.re*rotating.re + rotating.im*rotating.im)}		
		{@const phase = Math.atan2(rotating.im, rotating.re)}

		<path d="M0,0L{rotating.re*100} {-rotating.im*100}M100,0A 100 100 0 0 {rotating.im<0?1:0} {rotating.re/mag*100} {-rotating.im/mag*100}"  fill="none" stroke-dasharray="5 5" stroke="gray" stroke-width="3" fill-opacity="0.2"></path>
		<path d="M0,0L {num.re*100/nummag*mag} {-num.im*100/nummag*mag}A {100*mag} {100*mag} 0 0 {rotating.im<0?1:0} {Math.cos(numphase+phase)*100*mag} {-Math.sin(numphase+phase)*100*mag}"  fill="none" stroke-dasharray="5 5" stroke="gray" stroke-width="3" fill-opacity="0.2"></path>
		

		<path d="M0,0L100,0L{(num.re)*100},{-(num.im)*100}" fill="{num.color}" fill-opacity="0.05"></path>
		<path d="M0,0L{Math.cos(phase)*(mag)*100},{-Math.sin(phase)*(mag)*100}L{Math.cos(numphase+phase)*(nummag*mag)*100},{-Math.sin(numphase+phase)*(nummag*mag)*100}" fill="{num.color}" fill-opacity="0.05"></path>
		<path d="M0,0L{Math.cos(numphase+phase)*(nummag*mag)*100},{-Math.sin(numphase+phase)*(nummag*mag)*100}" stroke="lightblue" stroke-width="8" stroke-linecap="round" stroke-linejoin="round" ></path>
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-(numphase+phase)*180/Math.PI}) translate({100*nummag*mag}, 0)" fill="none" stroke="lightblue" stroke-width="8" stroke-linecap="round" stroke-linejoin="round"  />


		<path d="M0,0L{Math.cos(numphase+phase)*(nummag*mag)*100},{-Math.sin(numphase+phase)*(nummag*mag)*100}" stroke="{num.color}" stroke-width="3"></path>
		<polygon points="-12 10 -12 -10 3 0" transform="rotate({-(numphase+phase)*180/Math.PI}) translate({100*nummag*mag}, 0)" fill={num.color} />

		<path stroke-linejoin="round" pointer-events="none" d="M{rotating.re*100},{-rotating.im*100}m-15,10h24a 16 16 0 0 0 -10 -18z" stroke="{num.color}" fill="white" stroke-width="3"></path>
	{/if}

	<g>
		
	<text x="480" y="-10" text-anchor="end">Re</text>
	<text x="10" y="-480" text-anchor="start">Im</text>
	<text x="100" y="30" text-anchor="middle">1</text>
	<text x="-10" y="-90" text-anchor="end">1j</text>
	<text x="-100" y="30" text-anchor="middle">-1</text>
	<text x="-10" y="110" text-anchor="end">-1j</text>
	</g>
</svg>
</div>