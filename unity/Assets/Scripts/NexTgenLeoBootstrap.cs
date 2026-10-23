using UnityEngine;
using UnityEngine.UI;

namespace NexTgenLeo
{
    /// <summary>Playable placeholder scene. Replace primitive meshes with licensed art in Unity Editor.</summary>
    public sealed class NexTgenLeoBootstrap : MonoBehaviour
    {
        private CharacterController controller;
        private Transform avatar;
        private Camera followCamera;
        private Canvas canvas;
        private GameObject inventoryPanel;
        private Vector3 verticalVelocity;
        private const float Speed = 5f;
        private const float Gravity = -20f;
        private const float JumpSpeed = 7f;

        private void Start()
        {
            var floor = GameObject.CreatePrimitive(PrimitiveType.Plane);
            floor.name = "StarterForest_Ground";
            floor.transform.localScale = new Vector3(8, 1, 8);
            floor.GetComponent<Renderer>().material.color = new Color(0.19f, 0.40f, 0.24f);

            var actor = new GameObject("Player_MaleFemale_Placeholder");
            actor.transform.position = new Vector3(0, 0.1f, 0);
            controller = actor.AddComponent<CharacterController>();
            controller.height = 1.8f;
            controller.radius = 0.35f;
            controller.center = new Vector3(0, 0.9f, 0);
            avatar = actor.transform;

            var visual = GameObject.CreatePrimitive(PrimitiveType.Capsule);
            visual.name = "ReplaceWithRiggedModel";
            visual.transform.SetParent(actor.transform, false);
            visual.transform.localPosition = new Vector3(0, 0.9f, 0);
            visual.transform.localScale = new Vector3(0.7f, 0.9f, 0.7f);
            Destroy(visual.GetComponent<Collider>());

            var cameraObject = new GameObject("FollowCamera");
            followCamera = cameraObject.AddComponent<Camera>();
            followCamera.tag = "MainCamera";
            cameraObject.AddComponent<AudioListener>();

            var lightObject = new GameObject("Sun");
            var sun = lightObject.AddComponent<Light>();
            sun.type = LightType.Directional;
            sun.intensity = 1.2f;
            lightObject.transform.rotation = Quaternion.Euler(48, -35, 0);

            BuildInventoryUI();
        }

        private void Update()
        {
            if (controller == null) return;
            if (Input.GetKeyDown(KeyCode.B) || Input.GetKeyDown(KeyCode.I))
                inventoryPanel.SetActive(!inventoryPanel.activeSelf);

            var axis = new Vector2(Input.GetAxisRaw("Horizontal"), Input.GetAxisRaw("Vertical"));
            var movement = new Vector3(axis.x, 0, axis.y).normalized * Speed;
            if (movement.sqrMagnitude > 0.01f)
                avatar.forward = Vector3.Slerp(avatar.forward, movement.normalized, Time.deltaTime * 12f);
            if (controller.isGrounded)
            {
                verticalVelocity.y = -1f;
                if (Input.GetKeyDown(KeyCode.Space)) verticalVelocity.y = JumpSpeed;
            }
            verticalVelocity.y += Gravity * Time.deltaTime;
            controller.Move((movement + verticalVelocity) * Time.deltaTime);

            var desired = avatar.position + new Vector3(0, 5, -8);
            followCamera.transform.position = Vector3.Lerp(followCamera.transform.position, desired, Time.deltaTime * 10f);
            followCamera.transform.LookAt(avatar.position + Vector3.up * 1.1f);
        }

        private void BuildInventoryUI()
        {
            var canvasObject = new GameObject("NexTgenLeo_UI", typeof(Canvas), typeof(CanvasScaler), typeof(GraphicRaycaster));
            canvas = canvasObject.GetComponent<Canvas>();
            canvas.renderMode = RenderMode.ScreenSpaceOverlay;
            var scaler = canvasObject.GetComponent<CanvasScaler>();
            scaler.uiScaleMode = CanvasScaler.ScaleMode.ScaleWithScreenSize;
            scaler.referenceResolution = new Vector2(1280, 720);
            scaler.screenMatchMode = CanvasScaler.ScreenMatchMode.MatchWidthOrHeight;
            scaler.matchWidthOrHeight = 0.5f;

            inventoryPanel = new GameObject("InventoryPanel", typeof(RectTransform), typeof(Image));
            inventoryPanel.transform.SetParent(canvas.transform, false);
            var rect = inventoryPanel.GetComponent<RectTransform>();
            rect.anchorMin = new Vector2(0.05f, 0.10f);
            rect.anchorMax = new Vector2(0.95f, 0.90f);
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            inventoryPanel.GetComponent<Image>().color = new Color(0.035f, 0.09f, 0.18f, 0.95f);
            CreateLabel(inventoryPanel.transform, "CHARACTER STATUS", new Vector2(0.04f, 0.86f), new Vector2(0.45f, 0.98f));
            CreateLabel(inventoryPanel.transform, "INVENTORY   0 / 200", new Vector2(0.50f, 0.86f), new Vector2(0.97f, 0.98f));
            var gridObject = new GameObject("InventoryGrid", typeof(RectTransform), typeof(GridLayoutGroup));
            gridObject.transform.SetParent(inventoryPanel.transform, false);
            var gridRect = gridObject.GetComponent<RectTransform>();
            gridRect.anchorMin = new Vector2(0.50f, 0.07f);
            gridRect.anchorMax = new Vector2(0.97f, 0.82f);
            gridRect.offsetMin = gridRect.offsetMax = Vector2.zero;
            var grid = gridObject.GetComponent<GridLayoutGroup>();
            grid.cellSize = new Vector2(38, 38);
            grid.spacing = new Vector2(4, 4);
            grid.constraint = GridLayoutGroup.Constraint.FixedColumnCount;
            grid.constraintCount = 10;
            for (int i = 0; i < 100; i++)
            {
                var slot = new GameObject("Slot_" + i, typeof(RectTransform), typeof(Image));
                slot.transform.SetParent(gridObject.transform, false);
                slot.GetComponent<Image>().color = new Color(0.11f, 0.23f, 0.39f, 1f);
            }
            inventoryPanel.SetActive(false);
        }

        private static void CreateLabel(Transform parent, string value, Vector2 min, Vector2 max)
        {
            var labelObject = new GameObject(value, typeof(RectTransform), typeof(Text));
            labelObject.transform.SetParent(parent, false);
            var rect = labelObject.GetComponent<RectTransform>();
            rect.anchorMin = min;
            rect.anchorMax = max;
            rect.offsetMin = rect.offsetMax = Vector2.zero;
            var label = labelObject.GetComponent<Text>();
            label.font = Resources.GetBuiltinResource<Font>("LegacyRuntime.ttf");
            label.text = value;
            label.fontSize = 22;
            label.color = new Color(0.74f, 0.90f, 1f);
            label.alignment = TextAnchor.MiddleLeft;
        }
    }
}
