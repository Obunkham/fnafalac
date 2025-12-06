<!DOCTYPE html>
<html lang="it">
<head>
    <meta charset="UTF-8">
    <title>FNAF: Complete Shooter</title>
    <style>
        /* --- STILI GENERALI --- */
        body {
            margin: 0;
            background-color: #000;
            color: white;
            font-family: 'Courier New', Courier, monospace;
            overflow: hidden;
            user-select: none;
        }

        /* --- MENU --- */
        #main-menu {
            position: absolute; top: 0; left: 0; width: 100vw; height: 100vh;
            background: black; z-index: 300;
            display: flex; flex-direction: column; justify-content: center; align-items: center;
        }
        h1.title {
            font-size: 50px; color: #a00; text-shadow: 0 0 10px red;
            animation: glitch 2s infinite; text-align: center;
        }
        .start-btn {
            padding: 15px 40px; font-size: 24px; background: transparent;
            color: white; border: 2px solid white; cursor: pointer; margin-top: 20px;
            transition: all 0.2s;
        }
        .start-btn:hover { background: white; color: black; box-shadow: 0 0 20px white; }

        @keyframes glitch {
            0% { transform: skew(0deg); opacity: 1; }
            5% { transform: skew(-2deg); opacity: 0.9; }
            10% { transform: skew(2deg); opacity: 1; }
            100% { transform: skew(0deg); opacity: 1; }
        }

        /* --- GIOCO CONTAINER --- */
        #game-container {
            position: relative; width: 100vw; height: 100vh;
            background: radial-gradient(circle, #222 10%, #000 90%);
            display: none; cursor: crosshair;
        }

        /* --- UFFICIO --- */
        #office {
            width: 100%; height: 100%; position: absolute; z-index: 1;
            display: flex; justify-content: space-between; align-items: center;
        }

        .door-frame {
            width: 150px; height: 400px;
            background: #1a1a1a; border: 5px solid #000;
            display: flex; flex-direction: column; align-items: center; justify-content: flex-end;
            margin: 0 40px; position: relative; box-shadow: 0 0 30px #000 inset;
        }

        .hallway-view {
            position: absolute; top: 10px; width: 120px; height: 300px;
            background: black; opacity: 0.1; transition: opacity 0.1s; overflow: hidden;
        }
        .hallway-view.lit { opacity: 1; }

        /* --- MOSTRI --- */
        .monster-target {
            width: 100px; height: 200px; position: absolute; bottom: 0; left: 10px;
            cursor: crosshair; display: none; z-index: 10;
        }
        .body-shape {
            width: 80px; height: 150px; margin: 0 auto;
            border-radius: 20px 20px 0 0; position: relative;
        }
        .bonnie-color { background: #96c; border: 2px solid #539; }
        .chica-color { background: #cc0; border: 2px solid #880; }
        .eyes { position: absolute; top: 40px; width: 100%; display: flex; justify-content: center; gap: 10px; }
        .eye { width: 15px; height: 15px; background: white; border-radius: 50%; box-shadow: 0 0 5px red; }
        .pupil { width: 5px; height: 5px; background: black; border-radius: 50%; margin: 5px auto; }

        /* --- PISTOLA (MODELLO MIGLIORATO) --- */
        #player-gun-container {
            position: absolute;
            bottom: -50px; /* Posizione base */
            left: 50%;
            width: 0; height: 0;
            z-index: 50;
            pointer-events: none;
            transition: bottom 0.3s ease-in-out; /* Animazione rinfodero */
        }
        /* Classe per nascondere la pistola quando il monitor è su */
        #player-gun-container.holstered {
            bottom: -400px;
        }

        #gun-body {
            position: absolute;
            bottom: 0; left: -30px; /* Centrato rispetto al container */
            width: 60px; height: 220px;
            background: linear-gradient(90deg, #111, #333, #111);
            border: 2px solid black;
            border-radius: 5px 5px 0 0;
            /* Punto di rotazione in basso al centro */
            transform-origin: 50% 90%; 
        }
        /* Dettagli Pistola */
        #gun-body::before { /* Canna */
            content: ''; position: absolute; top: -20px; left: 15px;
            width: 30px; height: 40px; background: #555; border: 1px solid #222;
        }
        #gun-body::after { /* Mirino */
            content: ''; position: absolute; top: -25px; left: 28px;
            width: 4px; height: 10px; background: red;
        }
        
        .recoil { transform: translateY(20px) !important; }

        /* PROIETTILI ed ESPLOSIONI */
        .bullet {
            position: absolute; width: 12px; height: 12px; background: #ffdd00;
            border-radius: 50%; box-shadow: 0 0 10px #ffaa00; pointer-events: none;
            z-index: 99; transition: all 0.1s linear;
        }
        .explosion {
            position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
            width: 10px; height: 10px; background: orange; border-radius: 50%;
            animation: explode 0.3s forwards; display: none; z-index: 20;
        }
        @keyframes explode { 0% {width:10px; opacity:1;} 100% {width:200px; opacity:0;} }

        /* --- PULSANTI --- */
        .btn-light { 
            width: 80px; height: 80px; border-radius: 50%; background: #333; border: 4px solid #111;
            color: #ff0; font-weight: bold; display: flex; justify-content: center; align-items: center;
            cursor: pointer; margin-bottom: 20px; box-shadow: 0 5px 0 #000; z-index: 60;
            transition: all 0.1s;
        }
        .btn-light:active { transform: translateY(3px); box-shadow: 0 2px 0 #000; }
        .btn-light.lit-active { background: #fff; color: black; box-shadow: 0 0 20px yellow, inset 0 0 10px orange; }

        /* --- MONITOR --- */
        #monitor-toggle {
            position: absolute; bottom: 20px; right: 20px;
            width: 220px; height: 50px; background: #333; border: 2px solid #777;
            color: white; font-weight: bold; line-height: 50px; text-align: center;
            cursor: pointer; z-index: 100;
        }
        #monitor-toggle:hover { background: #555; }

        #camera-screen {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: #111; z-index: 90; display: none;
            border: 10px solid #222; box-sizing: border-box;
        }
        #cam-overlay {
            width: 100%; height: 100%; position: relative;
            background: repeating-linear-gradient(0deg, rgba(0,0,0,0.1), rgba(0,0,0,0.1) 2px, transparent 2px, transparent 4px);
            pointer-events: none;
        }
        #cam-feed-content {
            position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
            font-size: 80px; color: #444; font-weight: bold; text-align: center; width: 100%;
        }
        
        #map {
            position: absolute; bottom: 80px; right: 20px;
            width: 260px; height: 160px; background: rgba(0,0,0,0.8);
            border: 2px solid white; display: grid; grid-template-columns: 1fr 1fr; gap: 5px; padding: 10px;
            pointer-events: auto;
        }
        .cam-btn { background: #222; color: white; border: 1px solid #555; cursor: pointer; font-size: 11px; }
        .cam-btn.active { background: #0a0; }

        /* --- HUD --- */
        #hud { position: absolute; bottom: 20px; left: 20px; z-index: 100; font-size: 24px; text-shadow: 2px 2px 0 #000; pointer-events: none;}
        #clock { position: absolute; top: 20px; right: 20px; font-size: 32px; z-index: 100; pointer-events: none;}

        /* --- GAME OVER / WIN --- */
        #jumpscare, #win-screen {
            position: absolute; top: 0; left: 0; width: 100%; height: 100%;
            background: black; z-index: 500; display: none;
            justify-content: center; align-items: center; flex-direction: column;
        }
        #jumpscare-face {
            width: 400px; height: 400px; border-radius: 50%; animation: shake 0.1s infinite; margin-bottom: 20px;
        }
        @keyframes shake { 0% {transform: translate(2px, 2px);} 100% {transform: translate(-2px, -2px);} }
    </style>
</head>
<body>

<!-- MENU -->
<div id="main-menu">
    <h1 class="title">FIVE NIGHTS AT FREDDY'S<br>SHOOTER</h1>
    <p>1. Controlla le CAMERE per localizzare i nemici.</p>
    <p>2. Se spariscono dalla mappa, sono alla PORTA.</p>
    <p>3. Chiudi il Monitor. Accendi la LUCE (Click).</p>
    <p>4. SPARA (Click sul mostro). Spegni la luce.</p>
    <button class="start-btn" onclick="startGame()">INIZIA NOTTE</button>
</div>

<!-- GIOCO -->
<div id="game-container">
    
    <div id="hud">Energia: <span id="power">100</span>%</div>
    <div id="clock">12 AM</div>

    <!-- PISTOLA (Contenitore per animazione su/giù) -->
    <div id="player-gun-container">
        <!-- Corpo pistola che ruota -->
        <div id="gun-body"></div>
    </div>

    <!-- UFFICIO -->
    <div id="office">
        <!-- Lato Sinistro -->
        <div class="door-frame" id="left-ctrl">
            <div class="hallway-view" id="left-hall">
                <div class="monster-target" id="bonnie-target" onclick="shootMonster('Bonnie', event)">
                    <div class="explosion"></div>
                    <div class="body-shape bonnie-color">
                        <div class="eyes"><div class="eye"><div class="pupil"></div></div><div class="eye"><div class="pupil"></div></div></div>
                    </div>
                </div>
            </div>
            <!-- Toggle Light -->
            <div class="btn-light" onmousedown="event.stopPropagation(); toggleLight('left')">LIGHT</div>
        </div>

        <!-- Centro -->
        <div style="text-align:center; opacity: 0.3; pointer-events:none;">
            <h2>SECURITY<br>OFFICE</h2>
        </div>

        <!-- Lato Destro -->
        <div class="door-frame" id="right-ctrl">
            <div class="hallway-view" id="right-hall">
                <div class="monster-target" id="chica-target" onclick="shootMonster('Chica', event)">
                    <div class="explosion"></div>
                    <div class="body-shape chica-color">
                        <div class="eyes"><div class="eye"><div class="pupil"></div></div><div class="eye"><div class="pupil"></div></div></div>
                    </div>
                </div>
            </div>
            <!-- Toggle Light -->
            <div class="btn-light" onmousedown="event.stopPropagation(); toggleLight('right')">LIGHT</div>
        </div>
    </div>

    <!-- MONITOR CONTROLS -->
    <div id="monitor-toggle" onclick="toggleCamera(event)">APRI MONITOR</div>

    <!-- SCHERMATA CAMERE -->
    <div id="camera-screen">
        <div id="cam-overlay">
            <h2 style="position:absolute; top:20px; left:20px; color:white; margin:0;" id="cam-name">CAM 1A</h2>
            <div id="cam-feed-content"></div>
        </div>
        
        <div id="map">
            <button class="cam-btn active" onclick="switchCam(0, 'CAM 1A - Stage')">CAM 1A (Stage)</button>
            <button class="cam-btn" onclick="switchCam(1, 'CAM 1B - Dining')">CAM 1B (Dining)</button>
            <button class="cam-btn" onclick="switchCam(2, 'CAM 2A - W. Hall')">CAM 2A (Bonnie)</button>
            <button class="cam-btn" onclick="switchCam(3, 'CAM 2B - E. Hall')">CAM 2B (Chica)</button>
        </div>
    </div>

    <!-- END SCREENS -->
    <div id="jumpscare">
        <div id="jumpscare-face"></div>
        <h1 style="color:red; font-size: 50px;">GAME OVER</h1>
        <button class="start-btn" onclick="location.reload()">RIPROVA</button>
    </div>
    <div id="win-screen">
        <h1 style="color:#0f0; font-size: 50px;">6:00 AM</h1>
        <p>Ottimo lavoro.</p>
        <button class="start-btn" onclick="location.reload()">MENU</button>
    </div>
</div>

<script>
    // --- GESTIONE STATO ---
    let state = {
        power: 100,
        time: 0,
        gameStarted: false,
        isGameOver: false,
        cameraOpen: false,
        currentCamIndex: 0,
        lights: { left: false, right: false }
    };

    // Path logic: 0->1->2->4 (4=Porta)
    let bonnie = { name: "Bonnie", location: 0, path: [0, 1, 2, 4], el: document.getElementById('bonnie-target') };
    let chica = { name: "Chica", location: 0, path: [0, 1, 3, 4], el: document.getElementById('chica-target') };

    let gameLoop;

    // --- AVVIO GIOCO ---
    function startGame() {
        document.getElementById('main-menu').style.display = 'none';
        document.getElementById('game-container').style.display = 'block';
        state.gameStarted = true;
        gameLoop = setInterval(updateGame, 500);
        renderCamFeed();
    }

    // --- SISTEMA PISTOLA E MOUSE ---
    document.addEventListener('mousemove', (e) => {
        if (!state.gameStarted || state.isGameOver || state.cameraOpen) return;

        const gunContainer = document.getElementById('player-gun-container');
        const gunBody = document.getElementById('gun-body');
        
        // Calcolo rotazione
        const rect = gunContainer.getBoundingClientRect();
        const pivotX = rect.left; // Il container è left: 50%
        const pivotY = window.innerHeight; // Base schermo
        
        const deltaX = e.clientX - pivotX;
        const deltaY = e.clientY - pivotY;
        const angle = Math.atan2(deltaY, deltaX) * (180 / Math.PI) - 90; // -90 per correggere orientamento

        // Ruota solo il corpo della pistola, non il container
        gunBody.style.transform = `rotate(${angle}deg)`;
    });

    // Evento Sparo
    document.getElementById('game-container').addEventListener('mousedown', function(e) {
        if (!state.gameStarted || state.isGameOver || state.cameraOpen) return;
        
        // Evita di sparare se clicchi sull'interfaccia
        if (e.target.closest('.btn-light') || e.target.id === 'monitor-toggle') return;

        fireGunVisual();
        spawnBullet(e.clientX, e.clientY);
    });

    function fireGunVisual() {
        let gun = document.getElementById('gun-body');
        // Aggiungi rinculo visuale (traslazione Y temporanea)
        let originalTransform = gun.style.transform;
        gun.style.transform = originalTransform + " translateY(15px)";
        
        setTimeout(() => {
            gun.style.transform = originalTransform;
        }, 100);
    }

    function spawnBullet(targetX, targetY) {
        let b = document.createElement('div');
        b.className = 'bullet';
        
        // Il proiettile parte dal centro in basso
        let startX = window.innerWidth / 2;
        let startY = window.innerHeight - 50;

        b.style.left = startX + 'px';
        b.style.top = startY + 'px';
        document.body.appendChild(b);

        // Animazione verso il punto cliccato
        requestAnimationFrame(() => {
            b.style.left = targetX + 'px';
            b.style.top = targetY + 'px';
        });

        // Rimuovi dopo impatto
        setTimeout(() => b.remove(), 100);
    }

    // --- GESTIONE TELECAMERE ---
    window.toggleCamera = function(e) {
        if(e) e.stopPropagation();
        if (state.power <= 0) return;
        
        state.cameraOpen = !state.cameraOpen;
        
        let screen = document.getElementById('camera-screen');
        let gunContainer = document.getElementById('player-gun-container');
        let toggleBtn = document.getElementById('monitor-toggle');
        
        if (state.cameraOpen) {
            screen.style.display = 'block';
            toggleBtn.innerText = "CHIUDI MONITOR";
            // Nascondi pistola (animazione)
            gunContainer.classList.add('holstered');
            renderCamFeed();
        } else {
            screen.style.display = 'none';
            toggleBtn.innerText = "APRI MONITOR";
            // Mostra pistola
            gunContainer.classList.remove('holstered');
        }
    }

    window.switchCam = function(idx, name) {
        state.currentCamIndex = idx;
        document.getElementById('cam-name').innerText = name;
        document.querySelectorAll('.cam-btn').forEach(b => b.classList.remove('active'));
        event.target.classList.add('active');
        renderCamFeed();
    }

    function renderCamFeed() {
        if (!state.cameraOpen) return;
        let content = document.getElementById('cam-feed-content');
        content.innerHTML = "";
        
        let bPos = bonnie.path[bonnie.location];
        let cPos = chica.path[chica.location];
        
        if (bPos === state.currentCamIndex) content.innerHTML += `<div style="color:#96c;">BONNIE<br>[RILEVATO]</div><br>`;
        if (cPos === state.currentCamIndex) content.innerHTML += `<div style="color:#cc0;">CHICA<br>[RILEVATO]</div>`;
        
        if (content.innerHTML === "") content.innerHTML = `<span style="opacity:0.2;">SEGNALE VUOTO</span>`;
    }

    // --- GESTIONE LUCI (TOGGLE) ---
    window.toggleLight = function(side) {
        if (state.power <= 0 || state.cameraOpen) return;

        state.lights[side] = !state.lights[side]; // Inverti stato
        let isOn = state.lights[side];
        
        let hall = document.getElementById(side + '-hall');
        let btn = document.querySelector(`#${side}-ctrl .btn-light`);
        
        if (isOn) {
            hall.classList.add('lit');
            btn.classList.add('lit-active');
            checkDoorVisibility(side);
        } else {
            hall.classList.remove('lit');
            btn.classList.remove('lit-active');
            // Nascondi mostro quando spegni
            if(side==='left') bonnie.el.style.display='none';
            if(side==='right') chica.el.style.display='none';
        }
    }

    function checkDoorVisibility(side) {
        let bAtDoor = (bonnie.path[bonnie.location] === 4);
        let cAtDoor = (chica.path[chica.location] === 4);
        
        if (side === 'left' && bAtDoor) bonnie.el.style.display = 'block';
        if (side === 'right' && cAtDoor) chica.el.style.display = 'block';
    }

    // --- LOGICA SPARO A MOSTRO ---
    window.shootMonster = function(name, event) {
        if (state.cameraOpen) return; // Non puoi sparare col monitor
        
        let bot = (name === "Bonnie") ? bonnie : chica;
        
        // Se il mostro è effettivamente alla porta (Posizione 4)
        if (bot.path[bot.location] === 4) {
            let exp = bot.el.querySelector('.explosion');
            exp.style.display = 'block';
            
            setTimeout(() => {
                exp.style.display = 'none';
                bot.location = 0; // Reset allo Stage
                bot.el.style.display = 'none';
                updateVisuals();
            }, 300);
        }
    }

    // --- LOOP DI GIOCO ---
    function updateGame() {
        if (state.isGameOver) return;

        // Tempo
        state.time++;
        let hour = Math.floor(state.time / 60);
        document.getElementById('clock').innerText = (hour === 0 ? 12 : hour) + " AM";
        if (hour >= 6) winGame();

        // Energia
        let drain = 0.05;
        if (state.lights.left) drain += 0.2;
        if (state.lights.right) drain += 0.2;
        if (state.cameraOpen) drain += 0.15;
        
        state.power -= drain;
        if (state.power <= 0) gameOver("Blackout");
        document.getElementById('power').innerText = Math.floor(state.power);

        // AI Movimento
        if (Math.random() < 0.08) moveBot(bonnie);
        if (Math.random() < 0.08) moveBot(chica);
    }

    function moveBot(bot) {
        if (bot.location < 3) {
            bot.location++;
            if (state.cameraOpen) renderCamFeed();
        } else {
            // È alla porta (Location 3 -> Value 4)
            // Possibilità attacco
            if (Math.random() < 0.15) gameOver(bot.name);
        }
    }

    function updateVisuals() {
        // Aggiornamento generico se necessario
    }

    function gameOver(reason) {
        state.isGameOver = true;
        clearInterval(gameLoop);
        document.getElementById('jumpscare').style.display = 'flex';
        let face = document.getElementById('jumpscare-face');
        
        if(reason === "Bonnie") face.style.background = "radial-gradient(circle, #539, #000)";
        else if(reason === "Chica") face.style.background = "radial-gradient(circle, #cc0, #000)";
        else {
            face.style.background = "radial-gradient(circle, #420, #000)";
            face.innerHTML = "<div style='text-align:center; padding-top:140px; font-size:40px;'>NO POWER</div>";
        }
    }

    function winGame() {
        state.isGameOver = true;
        clearInterval(gameLoop);
        document.getElementById('win-screen').style.display = 'flex';
    }

</script>
</body>
</html>
