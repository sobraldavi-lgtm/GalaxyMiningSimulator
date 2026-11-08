#!/usr/bin/env python3
"""Reconstrói o mapa de Terra Nova com estética espacial e espaçamento maior.

Lê a arte original (commit ORIG), afasta cada instalação do centro, remove o
terreno antigo e gera: chão lunar com anéis de neon, caminhos, portais, postes,
crateras, rochas, painéis solares, antenas, cristais, minas profundas, borda,
nebulosas e cinturão de asteroides.

Uso (na raiz do projeto): python3 tools/build_space_map.py
Idempotente: sempre parte do commit ORIG.
"""
import colorsys, json, math, os, random, re, subprocess

ORIG = "af17020"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORLD = "src/world"
random.seed(11)


def git_json(name):
    out = subprocess.check_output(["git", "-C", ROOT, "show", f"{ORIG}:{WORLD}/{name}"])
    return json.loads(out.decode("utf-8"))


files = {}  # nome -> json carregado (arquivos referenciados por $path)


def load(name):
    if name not in files:
        files[name] = git_json(name)
    return files[name]


def translate(node, dx, dz):
    if not isinstance(node, dict):
        return
    props = node.get("$properties")
    if props and "Position" in props:
        props["Position"][0] += dx
        props["Position"][2] += dz
    if "$path" in node:
        translate(load(node["$path"])["tree"], dx, dz)
    for key, child in node.items():
        if not key.startswith("$"):
            translate(child, dx, dz)


def scale_sky(node, k_pos, k_size):
    if not isinstance(node, dict):
        return
    props = node.get("$properties")
    if props and "Position" in props:
        props["Position"][0] *= k_pos
        props["Position"][2] *= k_pos
        props["Size"] = [v * k_size for v in props["Size"]]
    for key, child in node.items():
        if not key.startswith("$"):
            scale_sky(child, k_pos, k_size)


# ---------------------------------------------------------------- helpers
def part(pos, size, color, material="SmoothPlastic", shape=None, orient=None, solid=False, **extra):
    props = {"Anchored": True, "Size": [round(v, 3) for v in size], "Position": [round(v, 3) for v in pos],
             "Color": [round(c, 3) for c in color], "Material": material,
             "TopSurface": "Smooth", "BottomSurface": "Smooth"}
    if not solid:
        props.update({"CanCollide": False, "CanTouch": False, "CanQuery": False, "CastShadow": False})
    if shape:
        props["Shape"] = shape
    if orient:
        props["Orientation"] = [round(v, 3) for v in orient]
    props.update(extra)
    return {"$className": "Part", "$properties": props}


def disc(x, y, z, radius, thickness, color, material="SmoothPlastic", solid=False, **extra):
    # cilindro com eixo vertical
    return part((x, y, z), (thickness, radius * 2, radius * 2), color, material, shape="Cylinder",
                orient=(0, 0, 90), solid=solid, **extra)


def light(color, rng=14, bright=1.0):
    return {"$className": "PointLight", "$properties": {
        "Color": list(color), "Range": rng, "Brightness": bright, "Shadows": False}}


def sign(pos, text, color, maxdist=140):
    p = part(pos, (1, 1, 1), color, Transparency=1)
    p["Label"] = {"$className": "BillboardGui", "$properties": {
        "Size": {"UDim2": [[0, 300], [0, 70]]}, "AlwaysOnTop": False, "MaxDistance": maxdist},
        "Text": {"$className": "TextLabel", "$properties": {
            "Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundColor3": [0.04, 0.05, 0.16],
            "BackgroundTransparency": 0.1, "Text": text, "TextColor3": list(color),
            "TextScaled": True, "TextWrapped": True, "Font": "GothamBlack"},
            "Corner": {"$className": "UICorner", "$properties": {"CornerRadius": {"UDim": [0, 10]}}},
            "Stroke": {"$className": "UIStroke", "$properties": {"Thickness": 3, "Color": [0.02, 0.02, 0.12]}}}}
    return p


def yaw_for_length(dx, dz):
    """Orientation Y para alinhar o eixo Z da peça com a direção (dx, dz)."""
    return math.degrees(math.atan2(-dx, -dz))


NAVY = (0.62, 0.5, 1.0)
STEEL = (0.95, 0.92, 1.0)
CYAN = (0.2, 0.85, 1.0)
MAGENTA = (1.0, 0.35, 0.8)
VIOLET = (0.7, 0.45, 1.0)
GOLD = (1.0, 0.82, 0.2)
ORANGE = (1.0, 0.55, 0.2)
GREEN = (0.35, 0.95, 0.55)

# ------------------------------------------------------------ layout
R = 250  # raio do chão
DELTAS = {"Shop": (-72, 0), "Hangar": (78, 6), "SaleStation": (17, 85), "PetShop": (-30, 45), "Mine": (0, -70)}
WING_X = {"East": 105, "West": -105}
WING_Z = -134
PATHS = [  # nome, ponto final, cor, texto do portal
    ("Shop", (-121, 0), GOLD, "LOJA"),
    ("Hangar", (126, 10), ORANGE, "HANGAR"),
    ("Sale", (71, 51), GREEN, "VENDA"),
    ("Pets", (-47, 57), MAGENTA, "PETS"),
    ("Mine", (0, -110), CYAN, "MINA"),
]
ZONES = [(-172, -116, -24, 24), (122, 178, -24, 40), (66, 106, 42, 76), (-68, -36, 48, 88),
         (-42, 42, -162, -106), (80, 132, -158, -110), (-132, -80, -158, -110)]
PLAZA_R = 30


def seg_dist(px, pz, ax, az, bx, bz):
    vx, vz = bx - ax, bz - az
    t = max(0, min(1, ((px - ax) * vx + (pz - az) * vz) / (vx * vx + vz * vz)))
    return math.hypot(px - (ax + t * vx), pz - (az + t * vz))


def free(x, z, margin=0, path_margin=11):
    if math.hypot(x, z) < PLAZA_R + margin:
        return False
    for x0, x1, z0, z1 in ZONES:
        if x0 - margin <= x <= x1 + margin and z0 - margin <= z <= z1 + margin:
            return False
    for _, (ex, ez), _, _ in PATHS:
        if seg_dist(x, z, 0, 0, ex, ez) < path_margin + margin:
            return False
    if abs(z - WING_Z) < 8 + margin and abs(x) < 130:
        return False
    return True


def random_spot(rmin, rmax, margin=0, taken=(), spacing=0):
    for _ in range(500):
        r = math.sqrt(random.uniform(rmin ** 2, rmax ** 2))
        a = random.uniform(0, math.tau)
        x, z = r * math.cos(a), r * math.sin(a)
        if free(x, z, margin) and all((x - px) ** 2 + (z - pz) ** 2 >= spacing ** 2 for px, pz in taken):
            return x, z
    return None


# ------------------------------------------------------ ores / wings
ORES = {
    "Silver": ("Prata cósmica", (0.82, 0.87, 0.95), "Metal", ("East", 0)),
    "Gold": ("Ouro estelar", (1.0, 0.78, 0.2), "Metal", ("East", 1)),
    "Emerald": ("Esmeralda alienígena", (0.15, 0.95, 0.5), "Neon", ("East", 2)),
    "Ruby": ("Rubi solar", (1.0, 0.18, 0.3), "Neon", ("West", 0)),
    "Obsidian": ("Obsidiana negra", (0.45, 0.2, 0.8), "Neon", ("West", 1)),
    "Diamond": ("Diamante galáctico", (0.7, 0.95, 1.0), "Neon", ("West", 2)),
}
BASE_DZ = [-57, -64, -71]
BASE_DX = [0, 3, 0]
BASE_ROT = [0, 25, 50]
SAMPLE_SIZE = [(2.5, 5, 2.5), (2.5, 6, 2.5), (2.5, 7, 2.5)]
SAMPLE_ROT = [(12, 0, 15), (12, 30, 15), (12, 60, 15)]


def ore_folder(oreid):
    name, color, mat, (wing, col) = ORES[oreid]
    x = WING_X[wing] + (col - 1) * 11
    zshift = DELTAS["Mine"][1]
    f = {"$className": "Folder"}
    for i in range(3):
        z = BASE_DZ[i] + zshift
        f[f"Base{i}"] = part((x + BASE_DX[i], 2.4, z), (7, 3, 6), (0.2, 0.19, 0.3), "Rock",
                             orient=(0, BASE_ROT[i], 0), solid=True)
        f[f"Sample{i}"] = part((x + BASE_DX[i], 5, z), SAMPLE_SIZE[i], color, mat,
                               orient=SAMPLE_ROT[i], solid=True)
    f["Name"] = sign((x, 10, -63 + zshift), f"{name}\nClique para minerar", color)
    return f


def deep_mines():
    mines = {"$className": "Folder"}
    for wing, label, glow in (("East", "MINA PROFUNDA\nLESTE", GOLD), ("West", "MINA PROFUNDA\nOESTE", VIOLET)):
        cx = WING_X[wing]
        sgn = 1 if wing == "East" else -1
        z0 = WING_Z
        mines[f"Platform{wing}"] = part((cx, 0.7, z0), (42, 0.4, 32), NAVY, "Slate", solid=True)
        mines[f"Rim{wing}"] = part((cx, 0.95, z0), (43.4, 0.12, 33.4), glow, "Neon")
        x_in = sgn * 31
        x_out = cx - sgn * 21
        mid, length = (x_in + x_out) / 2, abs(x_out - x_in)
        mines[f"Bridge{wing}"] = part((mid, 0.7, z0), (length, 0.4, 8), STEEL, "Metal", solid=True)
        mines[f"BridgeGlowA{wing}"] = part((mid, 0.95, z0 - 3.8), (length, 0.1, 0.35), glow, "Neon")
        mines[f"BridgeGlowB{wing}"] = part((mid, 0.95, z0 + 3.8), (length, 0.1, 0.35), glow, "Neon")
        for side in (-1, 1):
            mines[f"Pillar{wing}{side}"] = part((cx + side * 20, 6, z0 + 14), (2.4, 12, 2.4), STEEL, "Metal", solid=True)
            mines[f"PillarGlow{wing}{side}"] = part((cx + side * 20, 6, z0 + 14), (2.7, 9, 2.7), glow, "Neon",
                                                    Transparency=0.35)
        mines[f"Arch{wing}"] = part((cx, 12.5, z0 + 14), (44, 2, 2.6), STEEL, "Metal")
        mines[f"ArchGlow{wing}"] = part((cx, 11.3, z0 + 14), (40, 0.3, 2.8), glow, "Neon")
        mines[f"Sign{wing}"] = sign((cx, 17, z0 + 14), label, glow)
        for lx in (-17, 17):
            for lz in (-14, 14):
                mines[f"Lamp{wing}{lx}_{lz}"] = part((cx + lx, 4.2, z0 + lz), (1, 7, 1), STEEL, "Metal")
                orb = part((cx + lx, 8, z0 + lz), (2, 2, 2), glow, "Neon", shape="Ball")
                orb["Light"] = light(glow, 20, 1.2)
                mines[f"LampOrb{wing}{lx}_{lz}"] = orb
    return mines


# ------------------------------------------------------------ chão
LAV = (0.66, 0.55, 1.0)
CREAM = (1.0, 0.92, 0.6)
PINK = (1.0, 0.82, 0.95)


def ground():
    g = {"$className": "Folder"}
    g["Surface"] = disc(0, 0, 0, R, 1, LAV, solid=True)
    g["EdgeBand"] = disc(0, -0.2, 0, R + 3, 0.9, (1.0, 0.5, 0.85))
    layers = [(R - 4, -3, 7, (0.5, 0.35, 0.95)), (R - 7, -9, 6, (0.35, 0.45, 1.0)), (R - 14, -14, 6, (0.25, 0.78, 0.95)),
              (R - 32, -24, 14, (0.6, 0.4, 0.95)), (R - 72, -40, 18, (0.4, 0.5, 1.0)),
              (R - 122, -60, 22, (0.3, 0.78, 0.9)), (R - 172, -82, 26, (0.55, 0.4, 0.9))]
    for i, (rad, y, th, col) in enumerate(layers):
        g[f"Cliff{i}"] = disc(0, y, 0, rad, th, col)
    for i in range(16):
        a = i * math.tau / 16 + 0.2
        rad = random.uniform(70, 200)
        sz = random.uniform(18, 30)
        g[f"Drop{i}"] = part((rad * math.cos(a), -48 - sz * 0.4, rad * math.sin(a)), (sz, sz * 2, sz),
                             random.choice([(0.6, 0.45, 1.0), (0.4, 0.55, 1.0), (0.3, 0.8, 0.95), (1.0, 0.55, 0.85)]),
                             shape="Ball")
    y = 0.52
    for i, rad in enumerate((225, 180, 135, 90, 52)):
        g[f"Stripe{i}"] = disc(0, y, 0, rad + 0.9, 0.03, PINK if i % 2 == 0 else (0.7, 0.95, 1.0))
        y += 0.03
        g[f"StripeFill{i}"] = disc(0, y, 0, rad - 0.9, 0.03, LAV)
        y += 0.03
    taken = []
    for i in range(18):
        spot = random_spot(48, 215, margin=14, taken=taken, spacing=34)
        if not spot:
            continue
        taken.append(spot)
        rad = random.uniform(7, 17)
        x, z = spot
        g[f"CraterRim{i}"] = disc(x, 0.9, z, rad + 1.4, 0.05, (0.9, 0.82, 1.0))
        g[f"CraterFloor{i}"] = disc(x, 0.94, z, rad, 0.05, (0.5, 0.38, 0.92))
        if i % 3 == 0:
            tint = MAGENTA if i % 2 else CYAN
            glow = disc(x, 0.98, z, rad * 0.45, 0.04, tint, "Neon", Transparency=0.5)
            glow["Light"] = light(tint, rad * 2, 0.7)
            g[f"CraterGlow{i}"] = glow
    for i in range(110):
        spot = random_spot(32, 238, margin=2)
        if not spot:
            continue
        x, z = spot
        yaw = random.uniform(0, 90)
        c = random.choice([(1, 1, 1), (1, 0.95, 0.5), (0.7, 1, 1)])
        g[f"SparkleA{i}"] = part((x, 1.0, z), (1.8, 0.05, 0.35), c, "Neon", orient=(0, yaw, 0))
        g[f"SparkleB{i}"] = part((x, 1.0, z), (0.35, 0.05, 1.8), c, "Neon", orient=(0, yaw, 0))
    return g


def rim():
    f = {"$className": "Folder"}
    n = 40
    cols = [MAGENTA, CYAN, GOLD, GREEN, VIOLET]
    for i in range(n):
        a = i * math.tau / n
        x, z = (R - 4) * math.cos(a), (R - 4) * math.sin(a)
        tint = cols[i % 5]
        f[f"Pylon{i}"] = part((x, 4, z), (1.6, 7, 1.6), (1, 1, 1))
        orb = part((x, 8.4, z), (3, 3, 3), tint, "SmoothPlastic", shape="Ball")
        if i % 4 == 0:
            orb["Light"] = light(tint, 24, 1.0)
        f[f"PylonOrb{i}"] = orb
    return f


# ------------------------------------------------- caminhos e postes
def walkways():
    w = {"$className": "Folder"}
    lamps = {"$className": "Folder"}
    gates = {"$className": "Folder"}
    for name, (ex, ez), color, label in PATHS:
        length_total = math.hypot(ex, ez)
        ux, uz = ex / length_total, ez / length_total
        rx, rz = -uz, ux
        start = 17
        L = length_total - start
        cx, cz = ux * (start + L / 2), uz * (start + L / 2)
        yaw = yaw_for_length(ux, uz)
        width = 12
        w[f"{name}Slab"] = part((cx, 0.78, cz), (width, 0.32, L), CREAM, orient=(0, yaw, 0), solid=True)
        for side in (-1, 1):
            w[f"{name}Edge{side}"] = part((cx + rx * side * (width / 2 + 0.3), 0.8, cz + rz * side * (width / 2 + 0.3)),
                                         (1.0, 0.4, L), color, orient=(0, yaw, 0), solid=True)
        d, k = start + 4, 0
        while d < length_total - 3:
            w[f"{name}Dash{k}"] = part((ux * d, 0.97, uz * d), (2.6, 0.06, 1.0), color, "SmoothPlastic",
                                       orient=(0, yaw, 0))
            d += 6
            k += 1
        d, k = start + 18, 0
        while d < length_total - 8:
            for side in (-1, 1):
                px, pz = ux * d + rx * side * 9, uz * d + rz * side * 9
                lamps[f"{name}Pole{k}_{side}"] = part((px, 3.6, pz), (0.8, 6.4, 0.8), (1, 1, 1))
                orb = part((px, 7.6, pz), (2.6, 2.6, 2.6), color, "SmoothPlastic", shape="Ball")
                if k % 2 == 0:
                    orb["Light"] = light(color, 24, 1.1)
                lamps[f"{name}Orb{k}_{side}"] = orb
            d += 24
            k += 1
        gx, gz = ux * 40, uz * 40
        for side in (-1, 1):
            gates[f"{name}Post{side}"] = part((gx + rx * side * 8, 6.5, gz + rz * side * 8), (2.6, 13, 2.6), color, solid=True)
            gates[f"{name}Cap{side}"] = part((gx + rx * side * 8, 13.4, gz + rz * side * 8), (3.6, 3.6, 3.6),
                                             (1, 1, 1), shape="Ball")
        gates[f"{name}Beam"] = part((gx, 12.6, gz), (19, 2.2, 2.2), color, orient=(0, yaw + 90, 0))
        gates[f"{name}Holo"] = part((gx, 6.2, gz), (0.3, 11, 14), color, "Neon", orient=(0, yaw + 90, 0),
                                    Transparency=0.88)
        gates[f"{name}Sign"] = sign((gx, 17.5, gz), label, color, 130)
    return w, lamps, gates


# ---------------------------------------------------- cenário cósmico
def cotton_tree(f, i, x, z):
    h = random.uniform(6, 10)
    f[f"TreeTrunk{i}"] = part((x, h / 2, z), (1.6, h, 1.6), (0.75, 0.55, 0.95))
    cols = random.choice([[(1.0, 0.55, 0.85), (1.0, 0.75, 0.92)], [(0.35, 0.85, 1.0), (0.65, 0.95, 1.0)],
                          [(0.5, 0.95, 0.7), (0.75, 1.0, 0.85)], [(1.0, 0.85, 0.35), (1.0, 0.93, 0.6)]])
    f[f"TreeCap{i}_0"] = part((x, h + 2.2, z), (8, 6.5, 8), cols[0], shape="Ball")
    f[f"TreeCap{i}_1"] = part((x - 2.4, h + 0.4, z + 1.2), (5.2, 4.4, 5.2), cols[1], shape="Ball")
    f[f"TreeCap{i}_2"] = part((x + 2.6, h + 0.9, z - 1.0), (5.6, 4.6, 5.6), cols[1], shape="Ball")


def rocket(f, i, x, z):
    yaw = random.uniform(0, 360)
    body = random.choice([(1, 1, 1), (0.95, 0.9, 1.0)])
    red = random.choice([(1.0, 0.3, 0.4), (0.3, 0.6, 1.0), (1.0, 0.7, 0.2)])
    f[f"RocketBody{i}"] = disc(x, 7, z, 2.4, 11, body)
    f[f"RocketNose{i}"] = part((x, 13.2, z), (4.8, 6, 4.8), red, shape="Ball")
    f[f"RocketWindow{i}"] = part((x, 8.6, z - 2.1), (1.8, 1.8, 0.8), (0.4, 0.9, 1.0), "Neon", shape="Ball",
                                 orient=(0, yaw, 0))
    for k in range(3):
        a = math.radians(yaw + k * 120)
        f[f"RocketFin{i}_{k}"] = part((x + 2.6 * math.cos(a), 2.4, z + 2.6 * math.sin(a)), (0.6, 4, 2.4), red,
                                      orient=(0, -math.degrees(a), 0))
    f[f"RocketFlame{i}"] = part((x, 0.9, z), (3.2, 1.2, 3.2), (1.0, 0.7, 0.2), "Neon", shape="Ball")


def mini_planet(f, i, x, z):
    c = random.choice([(1.0, 0.6, 0.3), (0.4, 0.8, 1.0), (1.0, 0.5, 0.8), (0.6, 0.95, 0.5)])
    f[f"PlanetStand{i}"] = part((x, 2, z), (1.2, 4, 1.2), (1, 1, 1))
    f[f"PlanetBall{i}"] = part((x, 7, z), (7, 7, 7), c, shape="Ball")
    ring = part((x, 7, z), (0.35, 12.4, 12.4), (1.0, 0.95, 0.6), shape="Cylinder", orient=(25, 0, 90))
    f[f"PlanetRing{i}"] = ring


def sparkle_pole(f, i, x, z):
    h = random.uniform(9, 14)
    tint = random.choice([GOLD, MAGENTA, CYAN])
    f[f"StarPole{i}"] = part((x, h / 2, z), (0.7, h, 0.7), (1, 1, 1))
    top = part((x, h + 1.5, z), (0.6, 4.4, 0.6), tint, "Neon", orient=(0, 0, 0))
    top["Light"] = light(tint, 20, 1.0)
    f[f"StarTopV{i}"] = top
    f[f"StarTopH{i}"] = part((x, h + 1.5, z), (4.4, 0.6, 0.6), tint, "Neon")
    f[f"StarTopD1{i}"] = part((x, h + 1.5, z), (3.2, 0.5, 0.5), tint, "Neon", orient=(0, 0, 45))
    f[f"StarTopD2{i}"] = part((x, h + 1.5, z), (3.2, 0.5, 0.5), tint, "Neon", orient=(0, 0, -45))


def props():
    f = {"$className": "Folder"}
    taken = []

    def spot(rmin=36, rmax=232, margin=3, spacing=12):
        s = random_spot(rmin, rmax, margin, taken, spacing)
        if s:
            taken.append(s)
        return s

    for i in range(60):
        s = spot(spacing=9)
        if not s:
            continue
        x, z = s
        sx = random.uniform(3, 9)
        col = random.choice([(0.82, 0.76, 1.0), (0.92, 0.84, 1.0), (0.72, 0.86, 1.0), (1.0, 0.82, 0.92)])
        f[f"Rock{i}"] = part((x, sx * 0.3, z), (sx, sx * 0.65, sx * random.uniform(0.8, 1.2)), col, shape="Ball",
                             orient=(0, random.uniform(0, 360), 0))
    for i in range(26):
        s = spot(spacing=14)
        if s:
            cotton_tree(f, i, *s)
    for i in range(22):
        s = spot(spacing=14)
        if not s:
            continue
        x, z = s
        col = random.choice([CYAN, MAGENTA, VIOLET, GREEN, GOLD])
        for k in range(random.randint(3, 5)):
            h = random.uniform(3, 8)
            c = part((x + random.uniform(-2, 2), h / 2 + 0.4, z + random.uniform(-2, 2)), (1.4, h, 1.4), col, "Neon",
                     orient=(random.uniform(-14, 14), random.uniform(0, 360), random.uniform(-14, 14)),
                     Transparency=0.2)
            if k == 0 and i % 2 == 0:
                c["Light"] = light(col, 18, 0.9)
            f[f"Crystal{i}_{k}"] = c
    for i in range(6):
        s = spot(spacing=26)
        if s:
            rocket(f, i, *s)
    for i in range(8):
        s = spot(spacing=20)
        if s:
            mini_planet(f, i, *s)
    for i in range(14):
        s = spot(spacing=16)
        if s:
            sparkle_pole(f, i, *s)
    for i in range(10):
        s = spot(spacing=18)
        if not s:
            continue
        x, z = s
        yaw = random.uniform(0, 360)
        f[f"SolarPost{i}"] = part((x, 2.2, z), (0.8, 4.4, 0.8), (1, 1, 1))
        f[f"SolarPanel{i}"] = part((x, 5, z), (9, 0.5, 5.4), (0.35, 0.65, 1.0), orient=(-25, yaw, 0))
        f[f"SolarFrame{i}"] = part((x, 4.85, z), (9.6, 0.3, 6), (1, 0.9, 0.4), orient=(-25, yaw, 0))
    return f


def backdrop():
    f = {"$className": "Folder"}
    for i in range(30):
        a = random.uniform(0, math.tau)
        rad = random.uniform(300, 520)
        cx, cy, cz = rad * math.cos(a), random.uniform(40, 150), rad * math.sin(a)
        for k in range(random.randint(3, 5)):
            sz = random.uniform(22, 44)
            f[f"Cloud{i}_{k}"] = part((cx + k * 20 - 40, cy + random.uniform(-4, 6), cz + random.uniform(-14, 14)),
                                      (sz, sz * 0.55, sz * 0.8), (1.0, 0.96, 1.0), shape="Ball", Transparency=0.05)
    planets = [((-520, 170, -380), 90, (1.0, 0.62, 0.3)), ((560, 230, -300), 70, (0.4, 0.85, 1.0)),
               ((120, 300, 640), 110, (1.0, 0.5, 0.8)), ((-600, 140, 260), 60, (0.6, 0.95, 0.5)),
               ((380, 120, 480), 45, (1.0, 0.9, 0.35))]
    for i, (pos, size, col) in enumerate(planets):
        f[f"Planet{i}"] = part(pos, (size, size, size), col, shape="Ball")
        f[f"PlanetSpot{i}"] = part((pos[0] + size * 0.28, pos[1] + size * 0.2, pos[2] - size * 0.42),
                                   (size * 0.3, size * 0.3, size * 0.18), tuple(min(1, c + 0.18) for c in col),
                                   shape="Ball")
        f[f"PlanetRing{i}"] = part(pos, (size * 0.06, size * 1.9, size * 1.9), (1.0, 0.95, 0.7), shape="Cylinder",
                                   orient=(20 + i * 7, 0, 90 - i * 9), Transparency=0.25)
    for i in range(9):
        a = i * math.tau / 9 + 0.4
        rad = random.uniform(330, 440)
        x, z, y = rad * math.cos(a), rad * math.sin(a), random.uniform(10, 70)
        r = random.uniform(26, 48)
        f[f"IslandTop{i}"] = disc(x, y, z, r, 3, random.choice([(0.7, 0.95, 0.75), (0.8, 0.7, 1.0), (1.0, 0.8, 0.9)]))
        f[f"IslandMid{i}"] = disc(x, y - 4, z, r * 0.88, 6, (0.55, 0.4, 0.95))
        f[f"IslandLow{i}"] = disc(x, y - 11, z, r * 0.6, 9, (0.35, 0.55, 1.0))
        f[f"IslandTip{i}"] = part((x, y - 22, z), (r * 0.7, r * 0.9, r * 0.7), (0.3, 0.8, 0.95), shape="Ball")
        cotton_tree(f, 100 + i, x, z)
        f[f"TreeTrunk{100 + i}"]["$properties"]["Position"][1] += y + 1.5
        for key in (f"TreeCap{100 + i}_0", f"TreeCap{100 + i}_1", f"TreeCap{100 + i}_2"):
            f[key]["$properties"]["Position"][1] += y + 1.5
    return f


def plaza_orbs():
    f = {"$className": "Folder"}
    cols = [CYAN, MAGENTA, GOLD, VIOLET]
    for i in range(8):
        a = i * math.tau / 8
        x, z = 21 * math.cos(a), 21 * math.sin(a)
        o = part((x, 11 + (i % 2) * 2, z), (3, 3, 3), cols[i % 4], "SmoothPlastic", shape="Ball")
        o["Light"] = light(cols[i % 4], 22, 1.2)
        f[f"Orb{i}"] = o
    return f


KEEP_MATERIALS = {"SmoothPlastic", "Plastic", "Neon", "Glass", "Ice", "ForceField"}


def recolor(node):
    """Deixa a arte antiga clara, saturada e lisa (visual de brinquedo)."""
    if not isinstance(node, dict):
        return
    props = node.get("$properties")
    has_text = any(isinstance(c, dict) and c.get("$className") == "SurfaceGui" for c in node.values())
    if props and "Color" in props and props.get("Material") != "Neon" and not has_text:
        h, s, v = colorsys.rgb_to_hsv(*props["Color"])
        if s < 0.15:
            h, s = 0.72, 0.3
        s = min(1.0, max(s, 0.3) * 1.15)
        v = 0.72 + 0.28 * v
        props["Color"] = [round(c, 3) for c in colorsys.hsv_to_rgb(h, s, v)]
        if props.get("Material") not in KEEP_MATERIALS:
            props["Material"] = "SmoothPlastic"
    for key, child in node.items():
        if not key.startswith("$"):
            recolor(child)


# ----------------------------------------------------------- principal
def write(name, data):
    with open(os.path.join(ROOT, WORLD, name), "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")


def main():
    main_json = load("terra-nova.project.json")
    tree = main_json["tree"]

    translate(tree["Shop"], *DELTAS["Shop"])
    translate(tree["Hangar"], *DELTAS["Hangar"])
    translate(tree["Decorations"]["HangarLighting"], *DELTAS["Hangar"])
    translate(tree["SaleStation"], *DELTAS["SaleStation"])
    translate(tree["PetShop"], *DELTAS["PetShop"])
    for key in ("MiningAreas", "Cave"):
        translate(tree[key], *DELTAS["Mine"])
    for key in ("MineSetDressing", "CaveCrystals"):
        translate(tree["Decorations"][key], *DELTAS["Mine"])
    for ore in ("Iron", "Copper", "Crystal"):
        translate(tree["OreDeposits"][ore], *DELTAS["Mine"])

    tree.pop("Ground", None)
    for key in [k for k in tree["Decorations"] if k.startswith("Beacon")]:
        del tree["Decorations"][key]
    for ore in ORES:
        tree["OreDeposits"].pop(ore, None)
    land = load("orion-landscape.project.json")["tree"]
    land.pop("RouteNetwork", None)
    land.pop("SculptedLandscape", None)
    form = load("terra-nova-landform.project.json")["tree"]
    for key in ("ContinentalShelf", "Escarpments", "RegionalLandmarks"):
        form.pop(key, None)
    art = load("terra-nova-world-art.project.json")["tree"]
    art.pop("Biomes", None)
    art.pop("SouthOverlook", None)
    for key in [k for k in art["Skyline"] if k.startswith("Island")]:
        del art["Skyline"][key]
    scale_sky(art["Skyline"], 2.6, 1.6)
    sale = load("sale-station.project.json")["tree"]
    for key in [k for k in sale if re.match(r"Station(Deck|Guide)\d", k)]:
        del sale[key]

    recolor(tree)
    for name, data in files.items():
        if name != "terra-nova.project.json":
            recolor(data["tree"])
    for ore in ORES:
        tree["OreDeposits"][ore] = ore_folder(ore)
    walk, lamps, gates = walkways()
    expansion = {"name": "TerraNovaExpansion", "tree": {
        "$className": "Model",
        "Ground": ground(), "Rim": rim(), "Walkways": walk, "RouteLamps": lamps, "Gates": gates,
        "DeepMines": deep_mines(), "Props": props(), "PlazaOrbs": plaza_orbs(), "Backdrop": backdrop()}}
    tree["Expansion"] = {"$path": "terra-nova-expansion.project.json"}

    write("terra-nova-expansion.project.json", expansion)
    write("terra-nova.project.json", main_json)
    for name, data in files.items():
        if name != "terra-nova.project.json":
            write(name, data)


if __name__ == "__main__":
    main()
