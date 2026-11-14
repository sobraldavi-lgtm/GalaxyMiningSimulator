#!/usr/bin/env python3
"""Gera src/world/terra-nova-details.project.json: detalhes fixos do cenário.

- Globo holográfico de Terra Nova sobre a praça central.
- Acampamentos de mineradores em áreas livres do mapa.
- Equipamento de mineração (carrinhos em trilhos, caixotes, barris, lâmpadas)
  ao lado da plataforma da mina, fora da linha de visão dos depósitos.

As posições são validadas contra todas as peças já existentes nos arquivos do
cenário, para não cobrir caminhos, crateras nem construções.

Uso (na raiz do projeto): python3 tools/build_map_details.py
Determinístico: gera sempre o mesmo arquivo. Não altera os outros arquivos.
"""
import json, math, os, random

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
WORLD = os.path.join(ROOT, "src", "world")
OUT = "terra-nova-details.project.json"
GROUND_Y = 0.5  # topo do chão principal
random.seed(2026)


# ------------------------------------------------------------ ocupação
def collect_parts():
    """Lista (x, z, meia-largura, meia-profundidade, yaw) da base de cada peça existente,
    exceto o chão, discos gigantes, o que está no céu e o que está enterrado."""
    found = []

    def walk(node):
        if not isinstance(node, dict):
            return
        if "$path" in node:
            name = os.path.basename(node["$path"])
            if name != OUT:
                with open(os.path.join(WORLD, name), encoding="utf-8") as fh:
                    walk(json.load(fh)["tree"])
        props = node.get("$properties")
        if props and "Position" in props and "Size" in props and isinstance(props["Size"], list):
            size, pos = props["Size"], props["Position"]
            diagonal = math.sqrt(sum(v * v for v in size))
            if diagonal <= 140 and -1 <= pos[1] < 40:  # ignora chão/anéis, céu e peças enterradas
                orient = props.get("Orientation") or [0, 0, 0]
                width, depth = size[0], size[2]
                if abs(abs(orient[2]) - 90) < 1:  # cilindro/peça em pé: a base é Y × Z
                    width = size[1]
                found.append((pos[0], pos[2], width / 2, depth / 2, orient[1]))
        for key, child in node.items():
            if not key.startswith("$"):
                walk(child)

    with open(os.path.join(WORLD, "terra-nova.project.json"), encoding="utf-8") as fh:
        walk(json.load(fh)["tree"])
    return found


PARTS = collect_parts()
RESERVED = []  # locais já usados por este gerador


def free(x, z, radius):
    """Verdadeiro se um círculo de `radius` em (x, z) não toca a base de nenhuma peça."""
    for px, pz, half_w, half_d, yaw in PARTS:
        a = math.radians(yaw)
        dx, dz = x - px, z - pz
        # ponto no referencial local da peça (inverso da rotação em Y)
        lx = dx * math.cos(a) - dz * math.sin(a)
        lz = dx * math.sin(a) + dz * math.cos(a)
        ox, oz = max(abs(lx) - half_w, 0), max(abs(lz) - half_d, 0)
        if math.hypot(ox, oz) < radius:
            return False
    for rx, rz, rr in RESERVED:
        if math.hypot(rx - x, rz - z) < rr + radius:
            return False
    return True


# ------------------------------------------------------------ peças
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


def light(color, rng=14, bright=1.0):
    return {"$className": "PointLight", "$properties": {"Color": list(color), "Range": rng, "Brightness": bright,
                                                        "Shadows": False}}


def rotate(dx, dz, yaw):
    """Desloca (dx, dz) no referencial local girado por yaw (graus, como Orientation.Y)."""
    a = math.radians(yaw)
    return dx * math.cos(a) + dz * math.sin(a), -dx * math.sin(a) + dz * math.cos(a)


CANVAS = [(0.86, 0.42, 0.3), (0.3, 0.55, 0.78), (0.52, 0.42, 0.78), (0.3, 0.66, 0.56)]
WOOD = (0.5, 0.36, 0.26)
METAL = (0.2, 0.19, 0.3)
STEEL = (0.62, 0.66, 0.76)
GOLD = (1.0, 0.77, 0.19)
CYAN = (0.13, 0.88, 1.0)
ORES = [(0.75, 0.84, 1.0), (1.0, 0.59, 0.31), (0.24, 0.67, 1.0), (1.0, 0.78, 0.2)]


# ------------------------------------------------------------ globo da praça
def globe():
    f = {"$className": "Folder"}
    f["Hologram"] = part((0, 38, 0), (17, 17, 17), CYAN, "ForceField", shape="Ball")
    f["Core"] = part((0, 38, 0), (13, 13, 13), (0.16, 0.2, 0.5), shape="Ball", Transparency=0.35)
    for i, (dx, dy, dz, s) in enumerate([(3.5, 2, -4.6, 5), (-4.2, -1.5, -3.6, 4), (1, -4, 4.8, 4.5), (-3, 3.5, 4, 3.5)]):
        f[f"Land{i}"] = part((dx, 38 + dy, dz), (s, s * 0.7, s), (0.3, 0.85, 0.62), shape="Ball", Transparency=0.2)
    f["Ring"] = part((0, 38, 0), (0.3, 27, 27), (1.0, 0.86, 0.45), shape="Cylinder", orient=(18, 0, 78), Transparency=0.45)
    f["RingInner"] = part((0, 38, 0), (0.3, 22, 22), CYAN, shape="Cylinder", orient=(18, 0, 78), Transparency=0.7)
    f["Moon"] = part((15.5, 42, 3), (2.6, 2.6, 2.6), (0.9, 0.92, 1.0), shape="Ball")
    beam = part((0, 15.5, 0), (27, 1.4, 1.4), CYAN, "Neon", shape="Cylinder", orient=(0, 0, 90), Transparency=0.88)
    f["Beam"] = beam
    glow = part((0, 38, 0), (1, 1, 1), CYAN, Transparency=1)
    glow["Light"] = light(CYAN, 40, 1.2)
    f["Glow"] = glow
    return f


# ------------------------------------------------------------ acampamentos
def camp(index, x, z):
    f = {"$className": "Folder"}
    yaw = math.degrees(math.atan2(-x, -z))  # frente voltada para o centro do mapa
    canvas = CANVAS[index % len(CANVAS)]

    def at(dx, dz, y):
        ox, oz = rotate(dx, dz, yaw)
        return (x + ox, y, z + oz)

    # Barraca em cúpula, meio enterrada, com faixa e entrada.
    f["Tent"] = part(at(0, 3.2, GROUND_Y), (8.4, 6.6, 8.4), canvas, "Fabric", shape="Ball", solid=True)
    f["TentBand"] = part(at(0, 3.2, GROUND_Y + 1.2), (0.5, 8.5, 8.5), (0.96, 0.93, 0.85), "Fabric",
                         shape="Cylinder", orient=(0, 0, 90))
    f["TentDoor"] = part(at(0, 0.1, GROUND_Y + 0.9), (3, 3.4, 2.4), (0.1, 0.08, 0.18), shape="Ball")
    f["TentTop"] = part(at(0, 3.2, GROUND_Y + 3.6), (0.7, 0.7, 0.7), GOLD, "Neon", shape="Ball")
    # Fogueira com toras e fogo.
    for k in range(3):
        f[f"Log{k}"] = part(at(0, -3.6, GROUND_Y + 0.3), (2.4, 0.5, 0.5), WOOD, "Wood", shape="Cylinder",
                            orient=(0, yaw + k * 60, 0))
    ember = part(at(0, -3.6, GROUND_Y + 0.5), (0.9, 0.6, 0.9), (1.0, 0.55, 0.15), "Neon", shape="Ball")
    ember["Fire"] = {"$className": "Fire", "$properties": {"Heat": 6, "Size": 4,
                                                           "Color": [1.0, 0.55, 0.2], "SecondaryColor": [1.0, 0.85, 0.4]}}
    ember["Light"] = light((1.0, 0.6, 0.25), 18, 1.4)
    f["Ember"] = ember
    for k, (dx, dz) in enumerate([(-2.6, -3.6), (2.6, -3.6)]):
        f[f"Seat{k}"] = part(at(dx, dz, GROUND_Y + 0.55), (1.1, 1.3, 1.3), WOOD, "Wood", shape="Cylinder",
                             orient=(0, 0, 90), solid=True)
    # Caixotes de suprimentos e amostras de minério.
    f["CrateA"] = part(at(-5, 0.6, GROUND_Y + 1.1), (2.2, 2.2, 2.2), WOOD, "WoodPlanks", orient=(0, yaw + 12, 0), solid=True)
    f["CrateB"] = part(at(-5.2, 2.9, GROUND_Y + 0.9), (1.8, 1.8, 1.8), WOOD, "WoodPlanks", orient=(0, yaw - 20, 0), solid=True)
    ore = ORES[index % len(ORES)]
    for k, (dx, dz) in enumerate([(-4.7, 0.4), (-5.3, 0.9), (-4.9, 1.0)]):
        f[f"Sample{k}"] = part(at(dx, dz, GROUND_Y + 2.45), (0.8, 0.7, 0.8), ore, "Glass", shape="Ball", Reflectance=0.3)
    # Poste com lanterna e bandeira da Orion.
    f["Pole"] = part(at(5, 0.5, GROUND_Y + 3.5), (0.35, 7, 0.35), STEEL, "Metal")
    lamp = part(at(5, 0.5, GROUND_Y + 7.2), (0.9, 0.9, 0.9), GOLD, "Neon", shape="Ball")
    lamp["Light"] = light(GOLD, 20, 1.0)
    f["Lamp"] = lamp
    f["Flag"] = part(at(5.9, 0.5, GROUND_Y + 5.9), (1.8, 1.1, 0.1), canvas, "Fabric", orient=(0, yaw, 0))
    return f


def camps():
    f = {"$className": "Folder"}
    count = 0
    candidates = []
    for ring in (95, 130, 165, 200):
        for step in range(24):
            angle = step * math.tau / 24 + ring * 0.01
            candidates.append((ring * math.cos(angle), ring * math.sin(angle)))
    random.shuffle(candidates)
    for x, z in candidates:
        if count >= 6:
            break
        if free(x, z, 11):
            # mantém os acampamentos afastados entre si
            if all(math.hypot(x - rx, z - rz) > 80 for rx, rz, _ in RESERVED):
                f[f"Camp{count}"] = camp(count, x, z)
                RESERVED.append((x, z, 11))
                count += 1
    return f, count


# ------------------------------------------------------------ equipamento da mina
def cart(f, name, x, z, yaw, ore):
    def at(dx, dz, y):
        ox, oz = rotate(dx, dz, yaw)
        return (x + ox, y, z + oz)

    for side in (-1, 1):
        f[f"{name}Rail{side}"] = part(at(side * 1.1, 0, GROUND_Y + 0.15), (0.3, 0.3, 12), STEEL, "Metal", orient=(0, yaw, 0))
    for k in range(6):
        f[f"{name}Tie{k}"] = part(at(0, -5 + k * 2, GROUND_Y + 0.06), (3.2, 0.14, 0.6), WOOD, "Wood", orient=(0, yaw, 0))
    f[f"{name}Body"] = part(at(0, 0, GROUND_Y + 1.5), (2.6, 1.6, 3.8), METAL, "Metal", orient=(0, yaw, 0), solid=True)
    f[f"{name}Trim"] = part(at(0, 0, GROUND_Y + 2.35), (2.8, 0.2, 4), GOLD, "Metal", orient=(0, yaw, 0))
    for sx in (-1, 1):
        for sz in (-1, 1):
            f[f"{name}Wheel{sx}{sz}"] = part(at(sx * 1.1, sz * 1.2, GROUND_Y + 0.6), (0.3, 0.9, 0.9), STEEL, "Metal",
                                             shape="Cylinder", orient=(0, yaw, 0))
    for k, (dx, dz, s) in enumerate([(-0.4, -0.8, 1.3), (0.5, 0.2, 1.5), (-0.2, 1.0, 1.2), (0.1, -0.1, 1.0)]):
        f[f"{name}Ore{k}"] = part(at(dx, dz, GROUND_Y + 2.6 + (0.4 if k == 3 else 0)), (s, s * 0.8, s), ore, "Glass",
                                  shape="Ball", Reflectance=0.25)


def mine_gear():
    f = {"$className": "Folder"}
    placed = 0
    # Laterais da plataforma da mina (x = ±31): fora da linha de visão dos depósitos.
    candidates = [(-40, -119), (40, -119), (-40, -149), (40, -149), (-44, -116), (44, -116), (-44, -152), (44, -152)]
    i = -1
    for x, z in candidates:
        if placed >= 4 or not free(x, z, 7):
            continue
        yaw = 0
        i += 1
        RESERVED.append((x, z, 7))
        placed += 1
        if i % 2 == 0:
            cart(f, f"Cart{i}", x, z, yaw, ORES[i % len(ORES)])
        else:
            f[f"Crate{i}A"] = part((x, GROUND_Y + 1.2, z), (2.4, 2.4, 2.4), WOOD, "WoodPlanks", orient=(0, 15, 0), solid=True)
            f[f"Crate{i}B"] = part((x + 2.6, GROUND_Y + 1.0, z + 0.8), (2, 2, 2), WOOD, "WoodPlanks", orient=(0, -22, 0), solid=True)
            f[f"Crate{i}C"] = part((x + 0.6, GROUND_Y + 3.3, z + 0.2), (1.8, 1.8, 1.8), WOOD, "WoodPlanks", orient=(0, 40, 0), solid=True)
            for k in range(2):
                f[f"Barrel{i}_{k}"] = part((x - 2.6, GROUND_Y + 1.5, z - 1.6 + k * 2.6), (3, 2, 2), (0.24, 0.42, 0.62), "Metal",
                                           shape="Cylinder", orient=(0, 0, 90), solid=True)
                f[f"BarrelBand{i}_{k}"] = part((x - 2.6, GROUND_Y + 2.2, z - 1.6 + k * 2.6), (0.25, 2.1, 2.1), GOLD, "Metal",
                                               shape="Cylinder", orient=(0, 0, 90))
        # Lâmpada de trabalho em cada ponto.
        f[f"WorkPole{i}"] = part((x, GROUND_Y + 3, z + 5), (0.3, 6, 0.3), STEEL, "Metal")
        lamp = part((x, GROUND_Y + 6.2, z + 5), (1, 0.7, 1), CYAN, "Neon", shape="Ball")
        lamp["Light"] = light(CYAN, 18, 0.9)
        f[f"WorkLamp{i}"] = lamp
    return f, placed


def main():
    tree = {"$className": "Model"}
    tree["PlazaGlobe"] = globe()
    tree["Camps"], camp_count = camps()
    tree["MineGear"], gear_count = mine_gear()
    data = {"name": "TerraNovaDetails", "tree": tree}
    with open(os.path.join(WORLD, OUT), "w", encoding="utf-8") as fh:
        json.dump(data, fh, indent=2, ensure_ascii=False)
        fh.write("\n")
    total = sum(len([k for k in folder if not k.startswith("$")]) for folder in tree.values() if isinstance(folder, dict))
    print(f"{OUT}: {camp_count} acampamentos, {gear_count} pontos de equipamento na mina, {total} itens de nível superior")


if __name__ == "__main__":
    main()
