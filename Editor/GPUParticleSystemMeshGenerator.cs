#if UNITY_EDITOR
using UnityEditor;
using UnityEngine;

namespace GPUPS.Editor
{
    public class GPUParticleSystemMeshGenerator : EditorWindow
    {
        private int _particleCount = 10000;
        private string _savePath = "Assets/ParticleMesh.asset";

        [MenuItem("Tools/GPU Particle System/Generate Mesh")]
        private static void ShowWindow()
        {
            GetWindow<GPUParticleSystemMeshGenerator>("GPUPS Mesh Generator");
        }

        private void OnGUI()
        {
            _particleCount = EditorGUILayout.IntField("Particle Count", _particleCount);

            var totalQuads = _particleCount;
            var totalVerts = totalQuads * 4;
            EditorGUILayout.LabelField($"Total: {totalQuads:N0} quads, {totalVerts:N0} vertices");

            _savePath = EditorGUILayout.TextField("Save Path", _savePath);

            if (GUILayout.Button("Generate Mesh"))
            {
                GenerateMesh();
            }
        }

        private void GenerateMesh()
        {
            var totalQuads = _particleCount;
            var totalVertices = totalQuads * 4;
            var totalTriangles = totalQuads * 6;

            var vertices = new Vector3[totalVertices];
            var uvs = new Vector2[totalVertices];
            var uv2s = new Vector2[totalVertices];
            var triangles = new int[totalTriangles];

            var rng = new System.Random(12345);

            for (var p = 0; p < _particleCount; p++)
            {
                var v = p * 4;

                var rnd = new Vector3(
                    (float)rng.NextDouble(),
                    (float)rng.NextDouble(),
                    (float)rng.NextDouble()
                );
                // Ensure non-zero
                if (rnd.sqrMagnitude < 0.001f) rnd = new Vector3(0.1f, 0.1f, 0.1f);

                vertices[v + 0] = rnd;
                vertices[v + 1] = rnd;
                vertices[v + 2] = rnd;
                vertices[v + 3] = rnd;

                var particleIdUV = (p + 0.5f) / 1048576.0f;

                uvs[v + 0] = new Vector2(particleIdUV, 0);
                uvs[v + 1] = new Vector2(particleIdUV, 0);
                uvs[v + 2] = new Vector2(particleIdUV, 0);
                uvs[v + 3] = new Vector2(particleIdUV, 0);

                uv2s[v + 0] = new Vector2(0, 0);
                uv2s[v + 1] = new Vector2(0, 1);
                uv2s[v + 2] = new Vector2(1, 0);
                uv2s[v + 3] = new Vector2(1, 1);

                var t = p * 6;
                triangles[t + 0] = v + 0;
                triangles[t + 1] = v + 3;
                triangles[t + 2] = v + 2;
                triangles[t + 3] = v + 0;
                triangles[t + 4] = v + 1;
                triangles[t + 5] = v + 3;
            }

            var mesh = new Mesh
            {
                name = "GPUParticle_Mesh",
                indexFormat = totalVertices <= 65535 ? UnityEngine.Rendering.IndexFormat.UInt16 : UnityEngine.Rendering.IndexFormat.UInt32,
                vertices = vertices,
                uv = uvs,
                uv2 = uv2s,
                triangles = triangles
            };

            mesh.RecalculateBounds();
            mesh.bounds = new Bounds(Vector3.zero, Vector3.one * 1000);

            // Ensure directory exists
            var directory = System.IO.Path.GetDirectoryName(_savePath);
            if (!System.IO.Directory.Exists(directory) && directory != null) 
                System.IO.Directory.CreateDirectory(directory);

            AssetDatabase.CreateAsset(mesh, _savePath);
            AssetDatabase.SaveAssets();

            Debug.Log($"Generated GPU Particle Mesh:");
            Debug.Log($"  Particles: {_particleCount:N0}");
            Debug.Log($"  Vertices: {totalVertices:N0}");
            Debug.Log($"Saved to: {_savePath}");
        }
    }
}
#endif
