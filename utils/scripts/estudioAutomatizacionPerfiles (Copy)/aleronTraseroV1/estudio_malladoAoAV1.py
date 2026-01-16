import os
import subprocess
import shutil

# --- CONFIGURACIÓN DE RUTAS ---
# Usamos '../' porque las carpetas están afuera de aleronTraseroV1
PATH_GEOMETRIAS = "../GEOMETRIAS"
PATH_RESULTADOS_RAIZ = "../resultados_estudio_E423"
TARGET_STL = "constant/triSurface/e423_0.stl" # Verificá si tu HELYX usa 'constant/geometries'

# --- CONFIGURACIÓN DE LA MATRIZ ---
resoluciones = [(10, 1, 5), (40, 1, 20)] 
angulos_ataque = [0, 5, 10, 15, 20, 25, 30, 35] 
N_PROCS = 4

# --- FUNCIONES ---

def update_blockmesh(nx, ny, nz):
    """Modifica la línea 30 del blockMeshDict (índice 29)."""
    ruta = "system/blockMeshDict"
    with open(ruta, 'r') as f:
        lineas = f.readlines()
    lineas[29] = f"    hex (0 1 2 3 4 5 6 7) ({nx} {ny} {nz}) simpleGrading (1 1 1)\n"
    with open(ruta, 'w') as f:
        f.writelines(lineas)
    print(f"   [OK] L30 blockMeshDict -> ({nx} {ny} {nz})")

def run_logged_command(cmd, log_path):
    with open(log_path, "a") as f:
        f.write(f"\n--- EJECUTANDO: {cmd} ---\n")
        return subprocess.run(cmd, shell=True, stdout=f, stderr=f, text=True)

# --- BUCLE DE EJECUCIÓN ---
if not os.path.exists(PATH_RESULTADOS_RAIZ):
    os.makedirs(PATH_RESULTADOS_RAIZ)

for nx, ny, nz in resoluciones:
    path_res_malla = os.path.join(PATH_RESULTADOS_RAIZ, f"Malla_{nx}x{nz}")
    os.makedirs(path_res_malla, exist_ok=True)
    
    for angle in angulos_ataque:
        path_final = os.path.join(path_res_malla, f"AoA_{angle}")
        os.makedirs(path_final, exist_ok=True)
        log_caso = os.path.join(path_final, "workflow.log")
        
        print(f"\n{'='*60}\nSIMULANDO: Malla {nx}x{nz} | Ángulo {angle}°\n{'='*60}")

        # 1. Limpieza Nuclear
        print("   -> Limpiando caso con helyxClean...")
        subprocess.run("helyxClean", shell=True)
        if os.path.exists("constant/polyMesh"):
            shutil.rmtree("constant/polyMesh")

        # 2. Reemplazo de Geometría (Crucial)
        # Busca en ../GEOMETRIAS/{angle}/e423_0.stl
        source_stl = os.path.join(PATH_GEOMETRIAS, str(angle), "e423_0.stl")
        
        if os.path.exists(source_stl):
            # Asegurar que el directorio de destino existe
            os.makedirs(os.path.dirname(TARGET_STL), exist_ok=True)
            shutil.copy(source_stl, TARGET_STL)
            print(f"   [OK] STL reemplazado desde: {source_stl}")
        else:
            print(f"   [ERROR] No se encontró el STL en {source_stl}")
            continue # Salta al siguiente ángulo si falta la geometría

        # 3. Modificar Resolución
        update_blockmesh(nx, ny, nz)

        # 4. Flujo de Mallado
        print("   -> Generando Malla...")
        run_logged_command("blockMesh", log_caso)
        run_logged_command("decomposePar", log_caso)
        run_logged_command(f"mpirun -n {N_PROCS} helyxHexMesh -parallel -overwrite", log_caso)
        run_logged_command("reconstructParMesh -constant", log_caso)

        # 5. Flujo de Solver
        print("   -> Resolviendo...")
        run_logged_command("caseSetup", log_caso)
        subprocess.run("rm -rf processor*", shell=True) # Limpiar para redistribuir
        run_logged_command("decomposePar", log_caso)
        run_logged_command(f"mpirun -n {N_PROCS} helyxSolve -parallel", log_caso)

        # 6. Mover Resultados
        if os.path.exists("postProcessing"):
            shutil.move("postProcessing", os.path.join(path_final, "postProcessing"))
        
        # Guardar una copia del checkMesh para verificar que el ala es la correcta
        with open(os.path.join(path_final, "verif_geometria.txt"), "w") as f_v:
            subprocess.run("checkMesh | grep -A 8 'e423_0'", shell=True, stdout=f_v)

        print(f"   [ÉXITO] Resultados guardados en: {path_final}")

print("\n>>> ESTUDIO FINALIZADO <<<")
