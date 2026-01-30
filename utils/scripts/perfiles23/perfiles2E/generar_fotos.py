from paraview.simple import *
import sys, os

case_path = sys.argv[1]
output_dir = sys.argv[2]
os.makedirs(output_dir, exist_ok=True)
foam_file = os.path.join(case_path, "case.foam")

if not os.path.exists(foam_file): open(foam_file, 'w').close()

case = OpenFOAMReader(FileName=foam_file)
case.MeshRegions = ['internalMesh']
case.UpdatePipeline()

# SOLUCIÓN: Forzar la creación de la vista antes de pedir el tiempo
view = GetActiveViewOrCreate('RenderView')

# Asegurar que estamos en la última iteración
tiempos = case.TimestepValues
if tiempos:
    view.ViewTime = tiempos[-1]

# Tu configuración de cámara
view.ViewSize = [1600, 900]
view.CameraParallelScale = 0.8
view.Background = [1, 1, 1] 

# Renderizado de Velocidad
display = Show(case, view)
ColorBy(display, ('POINTS', 'U'))
u_lut = GetColorTransferFunction('U')
u_lut.RescaleTransferFunctionToDataRange()

# SOLUCIÓN SIGSEGV: En VM a veces hace falta forzar el renderizado offscreen si no hay GUI activa
SaveScreenshot(os.path.join(output_dir, "velocidad.png"), view, ImageResolution=[1600, 900])
