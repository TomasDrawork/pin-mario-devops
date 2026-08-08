const canvas = document.getElementById('gameCanvas');
const ctx = canvas.getContext('2d');

const uiOverlay = document.getElementById('ui-overlay');
const gameoverOverlay = document.getElementById('gameover-overlay');
const finalScoreSpan = document.getElementById('final-score');

// Game State
let gameState = 'START'; // START, PLAYING, GAMEOVER
let score = 0;
let distance = 0;
let enemies = [];
let particles = [];
let gameSpeed = 4;
let nextSpawn = 0;

// Web Audio API for Retro Sound Effects
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();

function playSound(type) {
    if (audioCtx.state === 'suspended') {
        audioCtx.resume();
    }
    
    const osc = audioCtx.createOscillator();
    const gain = audioCtx.createGain();
    osc.connect(gain);
    gain.connect(audioCtx.destination);

    if (type === 'jump') {
        osc.type = 'triangle';
        osc.frequency.setValueAtTime(150, audioCtx.currentTime);
        osc.frequency.exponentialRampToValueAtTime(600, audioCtx.currentTime + 0.15);
        gain.gain.setValueAtTime(0.15, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.15);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.15);
    } else if (type === 'hit') {
        osc.type = 'sawtooth';
        osc.frequency.setValueAtTime(300, audioCtx.currentTime);
        osc.frequency.linearRampToValueAtTime(80, audioCtx.currentTime + 0.4);
        gain.gain.setValueAtTime(0.2, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.4);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.4);
    } else if (type === 'coin') {
        osc.type = 'sine';
        osc.frequency.setValueAtTime(987.77, audioCtx.currentTime); // B5
        osc.frequency.setValueAtTime(1318.51, audioCtx.currentTime + 0.08); // E6
        gain.gain.setValueAtTime(0.1, audioCtx.currentTime);
        gain.gain.exponentialRampToValueAtTime(0.01, audioCtx.currentTime + 0.25);
        osc.start();
        osc.stop(audioCtx.currentTime + 0.25);
    }
}

// Background clouds/mountains
let scenery = [];
for (let i = 0; i < 5; i++) {
    scenery.push({
        x: Math.random() * canvas.width,
        y: 80 + Math.random() * 80,
        width: 60 + Math.random() * 80,
        height: 30 + Math.random() * 30,
        speed: 0.5 + Math.random() * 0.5
    });
}

// Player (Mario-like)
const mario = {
    x: 80,
    y: 300,
    width: 24,
    height: 32,
    velocityY: 0,
    gravity: 0.6,
    jumpForce: -11,
    isGrounded: true,
    frame: 0,
    animTimer: 0,

    update() {
        if (!this.isGrounded) {
            this.velocityY += this.gravity;
            this.y += this.velocityY;
            if (this.y >= 300) {
                this.y = 300;
                this.velocityY = 0;
                this.isGrounded = true;
            }
        } else {
            this.animTimer++;
            if (this.animTimer > 8) {
                this.frame = (this.frame + 1) % 4;
                this.animTimer = 0;
            }
        }
    },

    jump() {
        if (this.isGrounded) {
            this.velocityY = this.jumpForce;
            this.isGrounded = false;
            playSound('jump');
        }
    },

    draw() {
        ctx.save();
        // Simple Retro Mario representation in Canvas
        ctx.fillStyle = '#e52521'; // Red Overalls/Cap
        ctx.fillRect(this.x, this.y, this.width, this.height);
        
        ctx.fillStyle = '#002fbe'; // Blue pants
        ctx.fillRect(this.x + 2, this.y + 18, this.width - 4, 10);
        
        ctx.fillStyle = '#fbd000'; // Yellow buttons
        ctx.fillRect(this.x + 6, this.y + 19, 3, 3);
        ctx.fillRect(this.x + 15, this.y + 19, 3, 3);

        ctx.fillStyle = '#fbc093'; // Skin tone
        ctx.fillRect(this.x + 4, this.y + 4, this.width - 8, 10);
        
        ctx.fillStyle = '#653c00'; // Brown hair/shoes
        ctx.fillRect(this.x, this.y + 28, 8, 4);
        ctx.fillRect(this.x + 16, this.y + 28, 8, 4);
        
        // Eyes & mustache
        ctx.fillStyle = '#000000';
        ctx.fillRect(this.x + 14, this.y + 6, 3, 3);
        ctx.fillRect(this.x + 12, this.y + 10, 8, 2);

        // Cap bill
        ctx.fillStyle = '#e52521';
        ctx.fillRect(this.x + 2, this.y, this.width, 4);

        ctx.restore();
    }
};

// Bowser (Throwing fireballs from the right)
const bowser = {
    x: 540,
    y: 250,
    width: 64,
    height: 82,
    animTimer: 0,
    mouthOpen: false,

    update() {
        this.animTimer++;
        if (this.animTimer > 40) {
            this.mouthOpen = !this.mouthOpen;
            this.animTimer = 0;
        }
    },

    draw() {
        ctx.save();
        // Draw retro green shell / spikes / body
        ctx.fillStyle = '#43b047'; // Green shell
        ctx.fillRect(this.x + 15, this.y + 10, 40, 60);

        ctx.fillStyle = '#fbd000'; // Yellow skin
        ctx.fillRect(this.x, this.y + 20, 25, 50);
        ctx.fillRect(this.x + 20, this.y + 60, 25, 22);

        // Face & Horns
        ctx.fillStyle = '#ffffff'; // Horns
        ctx.fillRect(this.x + 35, this.y, 8, 12);
        
        ctx.fillStyle = '#e52521'; // Red hair
        ctx.fillRect(this.x + 10, this.y + 10, 30, 8);

        // Eyes
        ctx.fillStyle = '#e52521';
        ctx.fillRect(this.x + 4, this.y + 22, 6, 4);

        // Mouth (changes when shooting)
        ctx.fillStyle = '#fbd000';
        ctx.fillRect(this.x - 10, this.y + 35, 20, 15);
        if (this.mouthOpen) {
            ctx.fillStyle = '#000000';
            ctx.fillRect(this.x - 10, this.y + 40, 15, 8);
        }

        // Spikes on Shell
        ctx.fillStyle = '#ffffff';
        ctx.fillRect(this.x + 25, this.y + 20, 6, 6);
        ctx.fillRect(this.x + 45, this.y + 30, 6, 6);
        ctx.fillRect(this.x + 35, this.y + 45, 6, 6);

        ctx.restore();
    }
};

function spawnEnemy() {
    // Fireball
    enemies.push({
        x: bowser.x - 10,
        y: bowser.y + 40 + (Math.random() * 15 - 7),
        width: 18,
        height: 18,
        speed: 5 + Math.random() * 3,
        color: '#e52521',

        update() {
            this.x -= this.speed;
        },

        draw() {
            ctx.save();
            ctx.fillStyle = '#fbd000'; // Fire center
            ctx.fillRect(this.x + 2, this.y + 2, this.width - 4, this.height - 4);
            ctx.fillStyle = '#e52521'; // Fire edge
            ctx.strokeStyle = '#e52521';
            ctx.lineWidth = 2;
            ctx.strokeRect(this.x, this.y, this.width, this.height);
            ctx.restore();
        }
    });
    playSound('coin');
}

function checkCollision(r1, r2) {
    return r1.x < r2.x + r2.width &&
           r1.x + r1.width > r2.x &&
           r1.y < r2.y + r2.height &&
           r1.y + r1.height > r2.y;
}

function resetGame() {
    score = 0;
    distance = 0;
    enemies = [];
    particles = [];
    gameSpeed = 5;
    mario.y = 300;
    mario.velocityY = 0;
    mario.isGrounded = true;
    gameState = 'PLAYING';
    nextSpawn = 60;
    
    uiOverlay.classList.add('hidden');
    gameoverOverlay.classList.add('hidden');
}

function triggerGameOver() {
    gameState = 'GAMEOVER';
    playSound('hit');
    finalScoreSpan.textContent = score;
    gameoverOverlay.classList.remove('hidden');
}

// Controls
window.addEventListener('keydown', (e) => {
    if (e.code === 'Space' || e.code === 'ArrowUp') {
        e.preventDefault();
        if (gameState === 'PLAYING') {
            mario.jump();
        }
    }
});

uiOverlay.addEventListener('click', () => {
    if (gameState === 'START') resetGame();
});

gameoverOverlay.addEventListener('click', () => {
    if (gameState === 'GAMEOVER') resetGame();
});

// Main Loop
function loop() {
    ctx.clearRect(0, 0, canvas.width, canvas.height);

    // Sky Background
    ctx.fillStyle = '#221c38';
    ctx.fillRect(0, 0, canvas.width, canvas.height);

    // Scenery update/draw
    ctx.fillStyle = '#372d54';
    scenery.forEach(item => {
        if (gameState === 'PLAYING') {
            item.x -= item.speed;
            if (item.x + item.width < 0) {
                item.x = canvas.width;
            }
        }
        ctx.fillRect(item.x, item.y, item.width, item.height);
    });

    // Floor
    ctx.fillStyle = '#831412'; // Dark red block floor
    ctx.fillRect(0, 332, canvas.width, 68);
    ctx.fillStyle = '#b7201c';
    ctx.fillRect(0, 332, canvas.width, 6); // Ground trim

    // Grid lines for vintage retro feel
    ctx.strokeStyle = 'rgba(255, 255, 255, 0.05)';
    ctx.lineWidth = 1;
    for (let x = 0; x < canvas.width; x += 40) {
        ctx.beginPath();
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvas.height);
        ctx.stroke();
    }

    if (gameState === 'PLAYING') {
        distance++;
        if (distance % 50 === 0) {
            score += 10;
        }

        mario.update();
        bowser.update();

        // Enemy spawn manager
        nextSpawn--;
        if (nextSpawn <= 0) {
            spawnEnemy();
            nextSpawn = 80 + Math.random() * 70 - (score * 0.1); // Spawns faster as score increases
            if (nextSpawn < 40) nextSpawn = 40;
        }

        // Update & check enemies
        for (let i = enemies.length - 1; i >= 0; i--) {
            const enemy = enemies[i];
            enemy.update();
            
            if (checkCollision(mario, enemy)) {
                triggerGameOver();
                break;
            }

            if (enemy.x + enemy.width < 0) {
                enemies.splice(i, 1);
            }
        }
    }

    // Draw Entities
    mario.draw();
    bowser.draw();
    enemies.forEach(e => e.draw());

    // Score Board
    ctx.fillStyle = '#ffffff';
    ctx.font = '14px "Press Start 2P"';
    ctx.fillText(`SCORE: ${score}`, 20, 40);
    ctx.fillStyle = '#fbd000';
    ctx.fillText(`DEVOPS LEVEL: 1`, 400, 40);

    requestAnimationFrame(loop);
}

// Start loop
loop();
