#!/usr/bin/env python3
"""Gera a expansão de Terra Nova (minas profundas, postes, flora brilhante, órbitas).

Uso (na raiz do projeto): python3 tools/gen_expansion.py
Idempotente: reescreve terra-nova-expansion.project.json e garante as 6 novas
pastas em OreDeposits e a referência "Expansion" em terra-nova.project.json.
"""
import json, math, random, os

ROOT = os.path.join(os.path.dirname(__file__), "..", "src", "world")
MAIN = os.path.join(ROOT, "terra-nova.project.json")
EXP = os.path.join(ROOT, "terra-nova-expansion.project.json")


def part(pos, size, color, material="SmoothPlastic", **extra):
    props = {
        "Anchored": True, "Size": list(size), "Position": list(pos), "Color": list(color),
        "Material": material, "TopSurface": "Smooth", "BottomSurface": "Smooth",
    }
    props.update(extra)
    return {"$className": "Part", "$properties": props}


def nocollide(**extra):
    d = {"CanCollide": False, "CanTouch": False, "CanQuery": False, "CastShadow": False}
    d.update(extra)
    return d


def light(color, rng=12, bright=1.0):
    return {"$className": "PointLight", "$properties": {
        "Color": list(color), "Range": rng, "Brightness": bright, "Shadows": False}}


def sign(pos, text, color, maxdist=110):
    p = part(pos, (1, 1, 1), color, Transparency=1, **nocollide())
    p["Label"] = {"$className": "BillboardGui", "$properties": {
        "Size": {"UDim2": [[0, 290], [0, 66]]}, "AlwaysOnTop": False, "MaxDistance": maxdist},
        "Text": {"$className": "TextLabel", "$properties": {
            "Size": {"UDim2": [[1, 0], [1, 0]]}, "BackgroundColor3": [0.1, 0.07, 0.3],
            "BackgroundTransparency": 0.1, "Text": text, "TextColor3": list(color),
            "TextScaled": True, "TextWrapped": True, "Font": "GothamBlack"},
            "Corner": {"$className": "UICorner", "$properties": {"CornerRadius": {"UDim": [0, 10]}}},
            "Stroke": {"$className": "UIStroke", "$properties": {"Thickness": 3, "Color": [0.03, 0.02, 0.18]}}}}
    return p


# ---------------- minérios novos ----------------
ORES = {
    # id: (nome, cor, material da amostra, coluna)
    "Silver":   ("Prata cósmica", (0.82, 0.87, 0.95), "Metal", ("East", 0)),
    "Gold":     ("Ouro estelar", (1.0, 0.78, 0.2), "Metal", ("East", 1)),
    "Emerald":  ("Esmeralda alienígena", (0.15, 0.95, 0.5), "Neon", ("East", 2)),
    "Ruby":     ("Rubi solar", (1.0, 0.18, 0.3), "Neon", ("West", 0)),
    "Obsidian": ("Obsidiana negra", (0.45, 0.2, 0.8), "Neon", ("West", 1)),
    "Diamond":  ("Diamante galáctico", (0.7, 0.95, 1.0), "Neon", ("West", 2)),
}
WING_X = {"East": 60, "West": -60}
COLS = {"East": [49, 60, 71], "West": [-71, -60, -49]}
BASE_Z = [-57, -64, -71]
BASE_DX = [0, 3, 0]
BASE_ROT = [0, 25, 50]
SAMPLE_SIZE = [(2.5, 5, 2.5), (2.5, 6, 2.5), (2.5, 7, 2.5)]
SAMPLE_ROT = [(12, 0, 15), (12, 30, 15), (12, 60, 15)]


def ore_folder(oreid):
    name, color, mat, (wing, col) = ORES[oreid]
    x = COLS[wing][col]
    f = {"$className": "Folder"}
    for i in range(3):
        f[f"Base{i}"] = part((x + BASE_DX[i], 2.4, BASE_Z[i]), (7, 3, 6), (0.22, 0.2, 0.3), "Rock",
                             Orientation=[0, BASE_ROT[i], 0])
        f[f"Sample{i}"] = part((x + BASE_DX[i], 5, BASE_Z[i]), SAMPLE_SIZE[i], color, mat,
                               Orientation=list(SAMPLE_ROT[i]))
    f["Name"] = sign((x, 10, -63), f"{name}\nClique para minerar", color)
    f["Name"]["$properties"].update({"Transparency": 1})
    return f


# ---------------- expansão ----------------
def build_expansion():
    tree = {"$className": "Model"}

    # Minas profundas (plataformas, arcos e pontes)
    mines = {"$className": "Folder"}
    for wing, label, glow in (("East", "MINA PROFUNDA\nLESTE", (1.0, 0.8, 0.25)),
                              ("West", "MINA PROFUNDA\nOESTE", (0.75, 0.4, 1.0))):
        cx = WING_X[wing]
        sgn = 1 if wing == "East" else -1
        mines[f"Platform{wing}"] = part((cx, 0.7, -64), (42, 0.4, 32), (0.1, 0.09, 0.22), "Slate")
        mines[f"Rim{wing}"] = part((cx, 0.95, -64), (43.4, 0.12, 33.4), glow, "Neon", **nocollide())
        mines[f"Bridge{wing}"] = part((sgn * 35.5, 0.7, -64), (10, 0.4, 8), (0.16, 0.14, 0.34), "Metal")
        mines[f"BridgeGlow{wing}"] = part((sgn * 35.5, 0.95, -64), (10, 0.1, 0.35), glow, "Neon", **nocollide())
        for side in (-1, 1):
            mines[f"Pillar{wing}{side}"] = part((cx + side * 20, 6, -50), (2.4, 12, 2.4), (0.14, 0.12, 0.3), "Metal")
            mines[f"PillarGlow{wing}{side}"] = part((cx + side * 20, 6, -50), (2.6, 9, 2.6), glow, "Neon",
                                                    **nocollide(Transparency=0.35))
        mines[f"Arch{wing}"] = part((cx, 12.5, -50), (44, 2, 2.6), (0.14, 0.12, 0.3), "Metal")
        mines[f"ArchGlow{wing}"] = part((cx, 11.3, -50), (40, 0.3, 2.8), glow, "Neon", **nocollide())
        mines[f"Sign{wing}"] = sign((cx, 17, -50), label, glow)
        for lx in (-17, 17):
            for lz in (-52, -76):
                lamp = part((cx + lx, 4.2, lz), (1, 7, 1), (0.14, 0.12, 0.3), "Metal", **nocollide())
                mines[f"Lamp{wing}{lx}_{lz}"] = lamp
                orb = part((cx + lx, 8, lz), (2, 2, 2), glow, "Neon", Shape="Ball", **nocollide())
                orb["Light"] = light(glow, 18, 1.2)
                mines[f"LampOrb{wing}{lx}_{lz}"] = orb
    tree["DeepMines"] = mines

    # Postes ao longo dos caminhos
    lamps = {"$className": "Folder"}
    routes = [
        ("Shop", (1.0, 0.8, 0.25), [(-x, 0) for x in (14, 24, 34, 44)], "z"),
        ("Hangar", (1.0, 0.55, 0.2), [(x, 0) for x in (14, 24, 34, 44)], "z"),
        ("Mine", (0.2, 0.85, 1.0), [(0, -z) for z in (14, 22, 30, 38)], "x"),
    ]
    for name, color, points, spread in routes:
        for i, (x, z) in enumerate(points):
            for side in (-1, 1):
                px = x + (side * 6.5 if spread == "x" else 0)
                pz = z + (side * 6.5 if spread == "z" else 0)
                lamps[f"{name}Pole{i}_{side}"] = part((px, 3.4, pz), (0.7, 6.4, 0.7), (0.12, 0.1, 0.28), "Metal", **nocollide())
                orb = part((px, 7, pz), (1.8, 1.8, 1.8), color, "Neon", Shape="Ball", **nocollide())
                orb["Light"] = light(color, 16, 1.0)
                lamps[f"{name}Orb{i}_{side}"] = orb
    tree["RouteLamps"] = lamps

    # Flora alienígena brilhante
    random.seed(7)
    zones = [(-90, -48, -16, 16), (46, 96, -22, 32), (52, 84, -38, -16), (-34, 34, -84, -40),
             (38, 84, -86, -48), (-84, -38, -86, -48), (-34, -8, 12, 36)]
    flora = {"$className": "Folder"}
    palette = [(1.0, 0.35, 0.75), (0.25, 0.9, 1.0), (0.65, 0.4, 1.0), (0.4, 1.0, 0.6), (1.0, 0.75, 0.25)]
    placed = []
    attempts = 0
    while len(placed) < 30 and attempts < 4000:
        attempts += 1
        r = random.uniform(24, 52)
        a = random.uniform(0, math.tau)
        x, z = r * math.cos(a), r * math.sin(a)
        if abs(z) < 9 and abs(x) > 12: continue   # corredores leste/oeste
        if abs(x) < 9 and z < -10: continue       # corredor da mina
        if any(x0 <= x <= x1 and z0 <= z <= z1 for x0, x1, z0, z1 in zones): continue
        if any((x - px) ** 2 + (z - pz) ** 2 < 49 for px, pz in placed): continue
        placed.append((x, z))
        color = random.choice(palette)
        h = random.uniform(5, 9)
        i = len(placed)
        flora[f"Trunk{i}"] = part((x, h / 2 + 0.5, z), (0.9, h, 0.9), (0.2, 0.15, 0.35), "SmoothPlastic", **nocollide())
        for k, (dx, dy, dz, s) in enumerate([(0, 0.5, 0, 4.6), (-1.6, -0.5, 0.8, 3.0), (1.5, -0.2, -1.0, 3.4)]):
            cap = part((x + dx, h + 0.5 + dy, z + dz), (s, s * 0.7, s), color, "Neon", Shape="Ball",
                       **nocollide(Transparency=0.12))
            if k == 0:
                cap["Light"] = light(color, 16, 0.9)
            flora[f"Cap{i}_{k}"] = cap
    tree["GlowFlora"] = flora

    # Anéis flutuantes sobre a praça
    orbit = {"$className": "Folder"}
    cols = [(0.2, 0.85, 1.0), (1.0, 0.35, 0.75), (1.0, 0.8, 0.25), (0.65, 0.4, 1.0)]
    for i in range(8):
        a = i * math.tau / 8
        x, z = 21 * math.cos(a), 21 * math.sin(a)
        c = cols[i % 4]
        o = part((x, 11 + (i % 2) * 2, z), (2.6, 2.6, 2.6), c, "Neon", Shape="Ball", **nocollide(Transparency=0.1))
        o["Light"] = light(c, 20, 1.2)
        orbit[f"Orb{i}"] = o
    tree["PlazaOrbs"] = orbit
    return {"name": "TerraNovaExpansion", "tree": tree}


def main():
    with open(EXP, "w", encoding="utf-8") as f:
        json.dump(build_expansion(), f, indent=2, ensure_ascii=False)
        f.write("\n")
    with open(MAIN, encoding="utf-8") as f:
        main = json.load(f)
    tree = main["tree"]
    for oreid in ORES:
        tree["OreDeposits"][oreid] = ore_folder(oreid)
    tree["Expansion"] = {"$path": "terra-nova-expansion.project.json"}
    with open(MAIN, "w", encoding="utf-8") as f:
        json.dump(main, f, indent=2, ensure_ascii=False)
        f.write("\n")


if __name__ == "__main__":
    main()
