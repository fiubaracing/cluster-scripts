import os
import glob
import matplotlib.pyplot as plt

# --- CONFIGURACIÓN DE RUTAS ---
PATH_RESULTADOS = "./resultados_estudio_E423"
BUSQUEDA_ARCHIVO = "postProcessing/LD/*/liftDrag.dat" 

# --- 1. DATOS OFICIALES DEL PAPER (Tabla Re = 302300) ---
# Extraídos de la imagen 'image_db97ff.png'
paper_data = {
    "alpha": [-4.48, -3.38, -2.32, -0.78, 0.74, 2.28, 3.80, 5.33, 6.86, 8.40, 9.89, 11.42, 12.96],
    "cl": [0.275, 0.414, 0.724, 0.877, 1.023, 1.169, 1.304, 1.431, 1.556, 1.668, 1.769, 1.870, 1.944],
    "cd": [0.0623, 0.0518, 0.0180, 0.0172, 0.0184, 0.0193, 0.0199, 0.0201, 0.0219, 0.0237, 0.0259, 0.0279, 0.0319]
}

def extraer_ultimo_ld(path_file):
    """Extrae totalLift y drag de la última línea del archivo de CFD."""
    try:
        with open(path_file, 'r') as f:
            lineas = [l for l in f.readlines() if l.strip() and not l.startswith('#')]
            if not lineas: return None
            ultima = lineas[-1].split()
            cl = -float(ultima[1]) # Invertimos Downforce a Sustentación positiva
            cd = float(ultima[4])
            return cl, cd
    except: return None

# --- 2. PROCESAMIENTO DE TUS SIMULACIONES ---
datos_por_malla = {}
if os.path.exists(PATH_RESULTADOS):
    for malla in os.listdir(PATH_RESULTADOS):
        p_malla = os.path.join(PATH_RESULTADOS, malla)
        if not os.path.isdir(p_malla): continue
        datos_por_malla[malla] = {"aoa": [], "cl": [], "cd": []}
        for aoa_dir in os.listdir(p_malla):
            try: val_aoa = float(aoa_dir.split('_')[1])
            except: continue
            pattern = os.path.join(p_malla, aoa_dir, BUSQUEDA_ARCHIVO)
            archivos = glob.glob(pattern)
            if archivos:
                res = extraer_ultimo_ld(archivos[0])
                if res:
                    datos_por_malla[malla]["aoa"].append(val_aoa)
                    datos_por_malla[malla]["cl"].append(res[0])
                    datos_por_malla[malla]["cd"].append(res[1])

# --- 3. GENERAR GRÁFICOS DE VALIDACIÓN ---
fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(16, 7))

# Gráfico 1: Cl vs AoA
# Datos del Paper
ax1.plot(paper_data["alpha"], paper_data["cl"], 'k--o', label="Experimental (Paper Re=302k)", markersize=4)

# Datos de tus Mallas
for malla, d in datos_por_malla.items():
    if d["aoa"]:
        pts = sorted(zip(d["aoa"], d["cl"]))
        ax1.plot(*zip(*pts), '-s', label=f"CFD: {malla}", linewidth=2)

ax1.set_title("Validación: Coeficiente de Sustentación ($C_l$)", fontsize=12, fontweight='bold')
ax1.set_xlabel("Ángulo de Ataque [°]")
ax1.set_ylabel("$C_l$")
ax1.set_xlim([-12, 40]) # Ajustamos el zoom de los ejes
ax1.set_ylim([-1, 2.5])
ax1.grid(True, linestyle=':', alpha=0.6)
ax1.legend()

# Gráfico 2: Polar de Arrastre (Cl vs Cd)
# Datos del Paper
ax2.plot(paper_data["cd"], paper_data["cl"], 'k--o', label="Experimental (Paper Re=302k)", markersize=4)

# Datos de tus Mallas
for malla, d in datos_por_malla.items():
    if d["cl"]:
        pts = sorted(zip(d["cd"], d["cl"]))
        ax2.plot(*zip(*pts), '-^', label=f"CFD: {malla}", linewidth=2)

ax2.set_title("Polar de Arrastre ($C_l$ vs $C_d$)", fontsize=12, fontweight='bold')
ax2.set_xlabel("$C_d$ (Resistencia)")
ax2.set_ylabel("$C_l$ (Sustentación)")
ax2.grid(True, linestyle=':', alpha=0.6)
ax2.legend()

plt.tight_layout()
plt.savefig("validacion_E423_corregida.png", dpi=300)
print("\n>>> Gráfico guardado como 'validacion_E423_corregida.png'")
plt.show()
