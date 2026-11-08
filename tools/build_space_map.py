#!/usr/bin/env python3
"""Reconstrói o mapa de Terra Nova com estética espacial e espaçamento maior.

Lê a arte original (commit ORIG), afasta cada instalação do centro, remove o
terreno antigo e gera: chão lunar com anéis de neon, caminhos, portais, postes,
crateras, rochas, painéis solares, antenas, cristais, minas profundas, borda,
nebulosas e cinturão de asteroides.

Uso (na raiz do projeto): python3 tools/build_space_map.py
Idempotente: sempre parte do commit ORIG.
"""
import json, math, os, random, re, subprocess

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


NAVY = (0.07, 0.09, 0.17)
STEEL = (0.16, 0.19, 0.3)
CYAN = (0.1, 0.9, 1.0)
MAGENTA = (1.0, 0.25, 0.75)
VIOLET = (0.6, 0.35, 1.0)
GOLD = (1.0, 0.78, 0.25)
ORANGE = (1.0, 0.5, 0.2)
GREEN = (0.3, 1.0, 0.6)

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
def ground():
    g = {"$className": "Folder"}
    g["Surface"] = disc(0, 0, 0, R, 1, (0.085, 0.105, 0.19), "Slate", solid=True)
    g["EdgeGlow"] = disc(0, -0.1, 0, R + 2.2, 0.8, CYAN, "Neon")
    layers = [(R - 6, -4, 6, (0.05, 0.06, 0.12)), (R - 50, -12, 10, (0.06, 0.07, 0.14)),
              (R - 100, -24, 14, (0.07, 0.08, 0.16)), (R - 150, -40, 18, (0.06, 0.07, 0.13)),
              (R - 200, -58, 22, (0.05, 0.06, 0.11))]
    for i, (rad, y, th, col) in enumerate(layers):
        g[f"Under{i}"] = disc(0, y, 0, rad, th, col, "Slate")
    y = 0.52
    for i, rad in enumerate((225, 180, 135, 90, 52)):
        g[f"RingGlow{i}"] = disc(0, y, 0, rad + 0.35, 0.03, CYAN if i % 2 == 0 else VIOLET, "Neon")
        y += 0.03
        g[f"RingFill{i}"] = disc(0, y, 0, rad - 0.35, 0.03, (0.085, 0.105, 0.19), "Slate")
        y += 0.03
    taken = []
    for i in range(18):
        spot = random_spot(48, 215, margin=14, taken=taken, spacing=34)
        if not spot:
            continue
        taken.append(spot)
        rad = random.uniform(7, 17)
        x, z = spot
        g[f"CraterRim{i}"] = disc(x, 0.9, z, rad + 1.3, 0.05, (0.22, 0.26, 0.4), "Slate")
        g[f"CraterFloor{i}"] = disc(x, 0.94, z, rad, 0.05, (0.04, 0.05, 0.1), "Slate")
        if i % 3 == 0:
            tint = MAGENTA if i % 2 else CYAN
            glow = disc(x, 0.98, z, rad * 0.45, 0.04, tint, "Neon", Transparency=0.35)
            glow["Light"] = light(tint, rad * 2, 0.8)
            g[f"CraterGlow{i}"] = glow
    return g


def rim():
    f = {"$className": "Folder"}
    n = 40
    for i in range(n):
        a = i * math.tau / n
        x, z = (R - 4) * math.cos(a), (R - 4) * math.sin(a)
        tint = CYAN if i % 2 else VIOLET
        f[f"Pylon{i}"] = part((x, 4, z), (1.6, 7, 1.6), STEEL, "Metal")
        orb = part((x, 8.2, z), (2.2, 2.2, 2.2), tint, "Neon", shape="Ball")
        if i % 4 == 0:
            orb["Light"] = light(tint, 22, 1.0)
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
        w[f"{name}Slab"] = part((cx, 0.78, cz), (width, 0.32, L), STEEL, "Metal", orient=(0, yaw, 0), solid=True)
        for side in (-1, 1):
            w[f"{name}Edge{side}"] = part((cx + rx * side * (width / 2 - 0.3), 0.97, cz + rz * side * (width / 2 - 0.3)),
                                         (0.4, 0.1, L), color, "Neon", orient=(0, yaw, 0))
        d, k = start + 4, 0
        while d < length_total - 3:
            w[f"{name}Chev{k}"] = part((ux * d, 0.97, uz * d), (3.2, 0.08, 1.2), color, "Neon",
                                       orient=(0, yaw, 0), Transparency=0.35)
            d += 7
            k += 1
        d, k = start + 18, 0
        while d < length_total - 8:
            for side in (-1, 1):
                px, pz = ux * d + rx * side * 8, uz * d + rz * side * 8
                lamps[f"{name}Pole{k}_{side}"] = part((px, 3.6, pz), (0.7, 6.4, 0.7), STEEL, "Metal")
                orb = part((px, 7.4, pz), (1.9, 1.9, 1.9), color, "Neon", shape="Ball")
                if k % 2 == 0:
                    orb["Light"] = light(color, 22, 1.1)
                lamps[f"{name}Orb{k}_{side}"] = orb
            d += 24
            k += 1
        gx, gz = ux * 40, uz * 40
        for side in (-1, 1):
            gates[f"{name}Post{side}"] = part((gx + rx * side * 8, 6, gz + rz * side * 8), (1.4, 12, 1.4), STEEL, "Metal")
            gates[f"{name}PostGlow{side}"] = part((gx + rx * side * 8, 6, gz + rz * side * 8), (1.6, 10, 1.6), color,
                                                  "Neon", Transparency=0.3)
        gates[f"{name}Beam"] = part((gx, 12.4, gz), (18, 1.4, 1.4), STEEL, "Metal", orient=(0, yaw + 90, 0))
        gates[f"{name}Holo"] = part((gx, 7, gz), (0.3, 13, 16), color, "Neon", orient=(0, yaw + 90, 0),
                                    Transparency=0.9)
        gates[f"{name}Sign"] = sign((gx, 16.5, gz), label, color, 120)
    return w, lamps, gates


# ---------------------------------------------------- cenário espacial
def props():
    f = {"$className": "Folder"}
    taken = []

    def spot(rmin=36, rmax=232, margin=3, spacing=12):
        s = random_spot(rmin, rmax, margin, taken, spacing)
        if s:
            taken.append(s)
        return s

    for i in range(70):
        s = spot(spacing=9)
        if not s:
            continue
        x, z = s
        sx, sy, sz = random.uniform(2.5, 9), random.uniform(1.5, 6), random.uniform(2.5, 9)
        col = random.choice([(0.2, 0.23, 0.34), (0.26, 0.29, 0.42), (0.16, 0.19, 0.3)])
        f[f"Rock{i}"] = part((x, sy / 2 + 0.2, z), (sx, sy, sz), col, "Slate",
                             orient=(random.uniform(-8, 8), random.uniform(0, 360), random.uniform(-8, 8)))
    for i in range(24):
        s = spot(spacing=14)
        if not s:
            continue
        x, z = s
        col = random.choice([CYAN, MAGENTA, VIOLET, GREEN])
        for k in range(random.randint(3, 5)):
            h = random.uniform(3, 9)
            ox, oz = random.uniform(-2, 2), random.uniform(-2, 2)
            c = part((x + ox, h / 2 + 0.4, z + oz), (1.1, h, 1.1), col, "Neon",
                     orient=(random.uniform(-14, 14), random.uniform(0, 360), random.uniform(-14, 14)),
                     Transparency=0.12)
            if k == 0 and i % 2 == 0:
                c["Light"] = light(col, 18, 0.9)
            f[f"Crystal{i}_{k}"] = c
    for i in range(14):
        s = spot(spacing=16)
        if not s:
            continue
        x, z = s
        yaw = random.uniform(0, 360)
        f[f"SolarPost{i}"] = part((x, 2.2, z), (0.6, 4.4, 0.6), STEEL, "Metal")
        f[f"SolarPanel{i}"] = part((x, 5, z), (9, 0.3, 5), (0.1, 0.25, 0.6), "Glass", orient=(-25, yaw, 0))
        f[f"SolarGlow{i}"] = part((x, 4.85, z), (9.2, 0.1, 5.2), CYAN, "Neon", orient=(-25, yaw, 0), Transparency=0.6)
    for i in range(14):
        s = spot(spacing=14)
        if not s:
            continue
        x, z = s
        h = random.uniform(10, 18)
        tint = MAGENTA if i % 2 else CYAN
        f[f"Antenna{i}"] = part((x, h / 2, z), (0.5, h, 0.5), STEEL, "Metal")
        tip = part((x, h + 0.6, z), (1.2, 1.2, 1.2), tint, "Neon", shape="Ball")
        tip["Light"] = light(tint, 16, 1.0)
        f[f"AntennaTip{i}"] = tip
        f[f"AntennaBase{i}"] = part((x, 0.9, z), (3, 0.8, 3), NAVY, "Metal")
    for i in range(10):
        s = spot(spacing=18)
        if not s:
            continue
        x, z = s
        yaw = random.uniform(0, 360)
        f[f"DishPost{i}"] = part((x, 2.5, z), (0.8, 5, 0.8), STEEL, "Metal")
        f[f"Dish{i}"] = part((x, 6, z), (7, 1.4, 7), (0.8, 0.85, 0.95), "Metal", shape="Ball", orient=(-40, yaw, 0))
        f[f"DishTip{i}"] = part((x, 6.4, z), (0.7, 0.7, 0.7), GOLD, "Neon", shape="Ball")
    return f


def backdrop():
    f = {"$className": "Folder"}
    cols = [(0.6, 0.2, 0.9), (0.2, 0.4, 1.0), (1.0, 0.25, 0.65), (0.2, 0.9, 0.9)]
    for i in range(8):
        a = i * math.tau / 8 + 0.3
        rad = random.uniform(560, 700)
        f[f"Nebula{i}"] = part((rad * math.cos(a), random.uniform(90, 300), rad * math.sin(a)),
                               (330, 330, 330), cols[i % 4], "Neon", shape="Ball", Transparency=0.94)
    for i in range(70):
        a = random.uniform(0, math.tau)
        rad = random.uniform(300, 470)
        s = random.uniform(8, 38)
        pos = (rad * math.cos(a), random.uniform(-60, 140), rad * math.sin(a))
        f[f"Asteroid{i}"] = part(pos, (s, s * random.uniform(0.5, 0.9), s * random.uniform(0.7, 1.1)),
                                 random.choice([(0.18, 0.2, 0.3), (0.25, 0.27, 0.38)]), "Slate",
                                 orient=(random.uniform(0, 360), random.uniform(0, 360), random.uniform(0, 360)))
        if i % 5 == 0:
            f[f"AsteroidVein{i}"] = part((pos[0], pos[1] + s * 0.3, pos[2]), (s * 0.15, s * 0.5, s * 0.15),
                                         random.choice([CYAN, MAGENTA, VIOLET]), "Neon")
    return f


def plaza_orbs():
    f = {"$className": "Folder"}
    cols = [CYAN, MAGENTA, GOLD, VIOLET]
    for i in range(8):
        a = i * math.tau / 8
        x, z = 21 * math.cos(a), 21 * math.sin(a)
        o = part((x, 11 + (i % 2) * 2, z), (2.6, 2.6, 2.6), cols[i % 4], "Neon", shape="Ball", Transparency=0.1)
        o["Light"] = light(cols[i % 4], 20, 1.2)
        f[f"Orb{i}"] = o
    return f


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
    scale_sky(art["Skyline"], 2.6, 1.6)
    sale = load("sale-station.project.json")["tree"]
    for key in [k for k in sale if re.match(r"Station(Deck|Guide)\d", k)]:
        del sale[key]

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
