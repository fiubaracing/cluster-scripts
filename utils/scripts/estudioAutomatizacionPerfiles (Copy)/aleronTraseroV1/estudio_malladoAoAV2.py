import os
import subprocess
import shutil
import sys
import re

# --- CONFIGURACIÓN DE RUTAS ---
PATH_GEOMETRIAS = "../GEOMETRIAS"
PATH_RESULTADOS_RAIZ = "../resultados_estudio_E423"
TARGET_STL = "constant/triSurface/e423_0.stl"
N_PROCS = 4  

# --- CONFIGURACIÓN DE LA MATRIZ ---
resoluciones = [(10, 1, 5), (40, 1, 20)]
angulos_ataque = [-10, -5, 0, 5, 10, 15, 20, 25, 30, 35]

# --- FUNCIONES DE SOPORTE ---

def update_blockmesh(nx, ny, nz):
    ruta = "system/blockMeshDict"
    if not os.path.exists(ruta): return
    with open(ruta, 'r') as f:
        lineas = f.readlines()
    # Línea 30 (índice 29)
    lineas[29] = f"    hex (0 1 2 3 4 5 6 7) ({nx} {ny} {nz}) simpleGrading (1 1 1)\n"
    with open(ruta, 'w') as f:
        f.writelines(lineas)

def run_silent_command(cmd, log_path):
    with open(log_path, "a") as f:
        f.write(f"\n--- INICIO COMANDO: {cmd} ---\n")
        return subprocess.run(cmd, shell=True, stdout=f, stderr=f, text=True)

def extraer_ultimo_yplus(path_caso, path_final):
    # Buscamos el archivo yPlus.dat generado por la función en controlDict
    busqueda = subprocess.run("find postProcessing -name 'yPlus.dat'", 
                            shell=True, capture_output=True, text=True)
    if busqueda.stdout:
        ruta_archivo = busqueda.stdout.splitlines()[0]
        try:
            with open(ruta_archivo, 'r') as f:
                lineas_perfil = [l for l in f.readlines() if 'e423_0' in l]
                if lineas_perfil:
                    ultima = lineas_perfil[-1].split()
                    reporte = f"y+ Avg: {ultima[4]}"
                    with open(os.path.join(path_final, "yPlus_resumen.txt"), "w") as f_res:
                        f_res.write(f"Ultimo registro de e423_0:\n{lineas_perfil[-1]}")
                    return reporte
        except: pass
    return "y+ N/A"

def generar_fotos(path_destino):
    """Genera capturas usando pvpython con las coordenadas exactas de Juan Martin."""
    script_pv = f"""
from paraview.simple import *
import os
foam_file = 'case.foam'
if not os.path.exists(foam_file): open(foam_file, 'w').close()
case = OpenFOAMReader(FileName=foam_file)
case.MeshRegions = ['internalMesh']
UpdatePipeline()

view = GetActiveViewOrCreate('RenderView')
view.ViewSize = [1920, 1080]
view.OrientationAxesVisibility = 0
view.CameraParallelProjection = 1

# --- VISTA 1: CONTORNO GENERAL (U) ---
view.CameraPosition = [2.323959780721943, -8.112284643266985, 0.19442366861080823]
view.CameraFocalPoint = [2.323959780721943, 0.5188503116369247, 0.19442366861080823]
view.CameraViewUp = [0.0, 0.0, 1.0]
view.CameraParallelScale = 2.703021549686855

display = Show(case, view)
ColorBy(display, ('POINTS', 'U', 'Magnitude'))
u_lut = GetColorTransferFunction('U')
u_lut.ApplyPreset('Jet', True)
Render()
SaveScreenshot('{path_destino}/contorno_velocidad.png', view)

# --- VISTA 2: DETALLE MALLA (Zoom) ---
view.CameraPosition = [0.5883530340493396, -8.112284643266985, -0.06009114693509077]
view.CameraFocalPoint = [0.5883530340493396, 0.5188503116369247, -0.06009114693509077]
view.CameraParallelScale = 0.5882562438804982

display.Representation = 'Surface With Edges'
ColorBy(display, None)
Render()
SaveScreenshot('{path_destino}/detalle_malla.png', view)
"""
    with open("temp_pv.py", "w") as f: f.write(script_pv)
    subprocess.run(["pvpython", "--force-offscreen-rendering", "temp_pv.py"], 
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if os.path.exists("temp_pv.py"): os.remove("temp_pv.py")

# --- BUCLE PRINCIPAL ---

if not os.path.exists(PATH_RESULTADOS_RAIZ):
    os.makedirs(PATH_RESULTADOS_RAIZ)

print(f"Iniciando estudio de perfiles Eppler 423 para Juan Martin Gorza. [FIUBA Racing Team]")

for nx, ny, nz in resoluciones:
    print(f"\n[Malla {nx}x{nz}]")
    path_res_malla = os.path.join(PATH_RESULTADOS_RAIZ, f"Malla_{nx}x{nz}")
    os.makedirs(path_res_malla, exist_ok=True)
    
    for angle in angulos_ataque:
        sys.stdout.write(f"  -> AoA {angle}°: ")
        sys.stdout.flush()

        # AQUÍ ESTÁ LA CORRECCIÓN: Definimos la ruta de destino correctamente
        path_caso_final = os.path.join(path_res_malla, f"AoA_{angle}")
        os.makedirs(path_caso_final, exist_ok=True)
        
        log_wf = os.path.join(path_caso_final, "workflow.log")
        log_solv = os.path.join(path_caso_final, "solver.log")

        # 1. Limpieza y Setup STL
        subprocess.run("helyxClean > /dev/null 2>&1", shell=True)
        source_stl = os.path.join(PATH_GEOMETRIAS, str(angle), "e423_0.stl")
        
        if os.path.exists(source_stl):
            shutil.copy(source_stl, TARGET_STL)
        else:
            sys.stdout.write("Error: STL no encontrado.\n")
            continue

        update_blockmesh(nx, ny, nz)

        # 2. Pipeline de Mallado
        sys.stdout.write("Mallando... ")
        sys.stdout.flush()
        run_silent_command("blockMesh", log_wf)
        run_silent_command("decomposePar", log_wf)
        run_silent_command(f"mpirun -n {N_PROCS} helyxHexMesh -parallel -overwrite", log_wf)
        run_silent_command("reconstructParMesh -constant", log_wf)

        # 3. Pipeline de Solver
        sys.stdout.write("Resolviendo... ")
        sys.stdout.flush()
        run_silent_command("caseSetup", log_wf)
        subprocess.run("rm -rf processor*", shell=True)
        run_silent_command("decomposePar", log_wf)
        run_silent_command(f"mpirun -n {N_PROCS} helyxSolve -parallel", log_solv)

        # 4. Post-proceso e Imágenes
        generar_fotos(path_caso_final)
        info_yplus = extraer_ultimo_yplus(".", path_caso_final)

        # 5. Mover Resultados (Evita anidamiento)
        if os.path.exists("postProcessing"):
            target_pp = os.path.join(path_caso_final, "postProcessing")
            if os.path.exists(target_pp): shutil.rmtree(target_pp)
            shutil.move("postProcessing", target_pp)
        
        sys.stdout.write(f"Hecho. ({info_yplus})\n")
        sys.stdout.flush()

print(f"\n>>> ESTUDIO FINALIZADO. Resultados en: {PATH_RESULTADOS_RAIZ}")
