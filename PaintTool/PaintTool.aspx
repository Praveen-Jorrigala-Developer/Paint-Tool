<%@ Page Language="C#" AutoEventWireup="true" CodeFile="PaintTool.aspx.cs" Inherits="PaintTool.PaintTool" %>

<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>ASP.NET Fabric.js Paint Tool</title>
    <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.4.0/css/all.min.css" />
    <style>
        canvas {
            border: 1px solid black;
        }
        .toolbar button {
            margin: 3px;
            padding: 5px;
        }
         .icon-button {
        border: 1px solid black;
        padding: 5px;
        background-color: #efefef ;
        cursor: pointer;
        display: inline-block;
        border-radius: 4px;
        }

        .icon-button img {
            width: 20px;
            height: 20.5px;
            
        }       
        .icon-button:hover {
            background-color: #e0e0e0;
        }

        .icon-button:focus {
            outline: none;
            box-shadow: 0 0 2px 2px #90caf9;
        }
    </style>
    <script src="https://cdnjs.cloudflare.com/ajax/libs/fabric.js/5.3.0/fabric.min.js"></script>
</head>
<body>
    <form id="form1" runat="server">
        <asp:ScriptManager ID="ScriptManager1" runat="server" EnablePageMethods="true" />
        <asp:FileUpload ID="FileUpload1" runat="server" />
        <asp:Button ID="BtnUpload" runat="server" Text="Upload" OnClick="BtnUpload_Click" />
        <asp:HiddenField ID="UploadedImagePath" runat="server" ClientIDMode="Static" />
        <asp:HiddenField ID="CanvasDataURL" runat="server" ClientIDMode="Static" />      

        <div class="toolbar">
            <button type="button" onclick="setTool('select')"><img src="/icons/select.svg" alt="Select" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('fill')"><img src="/icons/fill.svg" alt="Fill" style="width: 20px; height: 20px;" /></button>
            <input type="color" onchange="setColor(this.value)" />            
            <select onchange="changeBrushSize(this.value)">
                <option value="2">Small Brush</option>
                <option value="5">Medium Brush</option>
                <option value="10">Large Brush</option>
            </select>
            <button id="btnPencil" type="button" onclick="setTool('pencil')"><img src="/icons/pencil.svg" alt="Pencil" style="width: 20px; height: 20px;" /></button>
            <button id="btnEraser" type="button" onclick="setTool('eraser')"><img src="/icons/eraser.svg" alt="Eraser" style="width: 20px; height: 20px;" /></button>
            <button id="btnCircle" type="button" onclick="setTool('circle')"><img src="/icons/circle.svg" alt="Circle" style="width: 20px; height: 20px;" /></button>
            <button id="btnLine" type="button" onclick="setTool('line')"><img src="/icons/line.svg" alt="Line" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('dot')"><img src="/icons/dot.png" alt="Dot" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('dotCircle')"><img src="/icons/dotted circle big.png" alt="Dot Circle" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('ellipseInEllipse')"><img src="/icons/double ellipse new.png" alt="Ellipse in Ellipse" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('cross')"><img src="/icons/x.svg" alt="Cross" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('greenArrow')"><img src="/icons/green arrow.png" alt="Green Arrow" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('blackArrow')"><img src="/icons/black arrow.png" alt="Black Arrow" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('redArrow')"><img src="/icons/red arrow.png" alt="Red Arrow" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="setTool('chevronDouble')"><img src="/icons/double arrow.png" alt="Chevron Double" style="width: 20px; height: 20px;" /></button>
            <button id="btnRectangle" type="button" onclick="setTool('rectangle')"><img src="/icons/rectangle.svg" alt="Rectangle" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="undo()"><img src="/icons/undo.svg" alt="Undo" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="redo()"><img src="/icons/redo.svg" alt="Redo" style="width: 20px; height: 20px;" /></button>
            <button type="button" onclick="clearAll()"><img src="/icons/clear.svg" alt="Clear All" style="width: 20px; height: 20px;" /></button>
            <asp:LinkButton ID="LinkButton1" runat="server" OnClick="BtnDownloadCanvas_Click" 
                OnClientClick="return prepareCanvasDownload();" CssClass="icon-button">
                <img src="/icons/save.svg" alt="Save" />
            </asp:LinkButton>
        </div>

        <canvas id="drawingCanvas" width="1200" height="550"></canvas>
    </form>

<script>
    const canvas = new fabric.Canvas('drawingCanvas', {
        isDrawingMode: false,
        selection: false
    });

    let currentTool = 'none';
    let color = '#000000';
    let isDrawing = false;
    let origX, origY, shape;
    let undoStack = [];
    let redoStack = [];
    let backgroundImage = null;
    const MAX_STACK_SIZE = 50;
    let isStateSaving = false;

    function saveCanvasState() {
        if (isStateSaving) return;
        isStateSaving = true;

        try {
            const state = canvas.toJSON(['selectable']);
            if (backgroundImage) {
                state.backgroundImage = {
                    type: 'image',
                    src: backgroundImage.src,
                    scaleX: backgroundImage.scaleX,
                    scaleY: backgroundImage.scaleY
                };
            }
            const stateString = JSON.stringify(state);

            if (undoStack.length === 0 || stateString !== undoStack[undoStack.length - 1]) {
                undoStack.push(stateString);
                if (undoStack.length > MAX_STACK_SIZE) undoStack.shift();
                redoStack = [];
            }
        } catch (e) {
            console.error('Error saving canvas state:', e);
        } finally {
            isStateSaving = false;
        }
    }

    function loadCanvasState(stateJSON) {
        try {
            canvas.clear();
            canvas.loadFromJSON(stateJSON, () => {
                const imgPath = document.getElementById("UploadedImagePath").value;
                if (imgPath) {
                    fabric.Image.fromURL(imgPath, (img) => {
                        canvas.setBackgroundImage(img, canvas.renderAll.bind(canvas), {
                            scaleX: canvas.width / img.width,
                            scaleY: canvas.height / img.height
                        });
                        backgroundImage = img;
                        canvas.renderAll();
                    }, { crossOrigin: 'anonymous' });
                } else {
                    canvas.setBackgroundImage(null, canvas.renderAll.bind(canvas));
                    backgroundImage = null;
                    canvas.renderAll();
                }
            });
        } catch (e) {
            console.error('Error loading canvas state:', e);
        }
    }

    function undo() {
        if (undoStack.length <= 1) return;
        try {
            const currentState = undoStack.pop();
            redoStack.push(currentState);
            if (redoStack.length > MAX_STACK_SIZE) redoStack.shift();
            const previousState = undoStack[undoStack.length - 1];
            loadCanvasState(previousState);
        } catch (e) {
            console.error('Error during undo:', e);
        }
    }

    function redo() {
        if (redoStack.length === 0) return;
        try {
            const nextState = redoStack.pop();
            undoStack.push(nextState);
            if (undoStack.length > MAX_STACK_SIZE) undoStack.shift();
            loadCanvasState(nextState);
        } catch (e) {
            console.error('Error during redo:', e);
        }
    }

    function clearAll() {
        try {
            canvas.clear();
            undoStack = [];
            redoStack = [];
            if (backgroundImage) {
                canvas.setBackgroundImage(backgroundImage, canvas.renderAll.bind(canvas));
            }
            canvas.renderAll();
            saveCanvasState();
        } catch (e) {
            console.error('Error clearing canvas:', e);
        }
    }

    function setTool(tool) {
        currentTool = tool;
        canvas.isDrawingMode = false;
        canvas.selection = false;
        canvas.getObjects().forEach(obj => obj.set('selectable', false));

        if (tool === 'select') {
            canvas.selection = true;
            canvas.getObjects().forEach(obj => obj.set('selectable', true));
        } else if (tool === 'pencil') {
            canvas.isDrawingMode = true;
            canvas.freeDrawingBrush = new fabric.PencilBrush(canvas);
            canvas.freeDrawingBrush.color = color;
        } else if (tool === 'eraser') {
            canvas.isDrawingMode = true;
            canvas.freeDrawingBrush = new fabric.PencilBrush(canvas);
            canvas.freeDrawingBrush.color = '#FFFFFF';
            canvas.freeDrawingBrush.width = 10;
            canvas.selection = false;
        } else if (tool === 'fill') {
            canvas.isDrawingMode = false;
            canvas.selection = false;
        }
    }

    function setColor(c) {
        color = c;
        if (currentTool === 'pencil' || currentTool === 'eraser') {
            canvas.freeDrawingBrush.color = currentTool === 'eraser' ? '#FFFFFF' : color;
        }
    }

    function changeBrushSize(size) {
        if (canvas.isDrawingMode) {
            canvas.freeDrawingBrush.width = parseInt(size, 10);
        }
    }

    function createShape(tool, x, y) {
        const commonProps = { selectable: false, stroke: color, fill: 'transparent', strokeWidth: 2 };
        switch (tool) {
            case 'rectangle':
                return new fabric.Rect({ left: x, top: y, width: 0, height: 0, ...commonProps });
            case 'circle':
                return new fabric.Ellipse({ left: x, top: y, rx: 0, ry: 0, ...commonProps });
            case 'line':
                return new fabric.Line([x, y, x, y], { stroke: color, strokeWidth: 2, selectable: false });
            case 'dot':
                return new fabric.Circle({ left: x, top: y, radius: 2, fill: color, selectable: false, originX: 'center', originY: 'center' });
            case 'dotCircle':
                return new fabric.Group([], { left: x, top: y, originX: 'center', originY: 'center', selectable: false });
            case 'ellipseInEllipse':
                const outer = new fabric.Ellipse({
                    left: x,
                    top: y,
                    rx: 0,
                    ry: 0,
                    ...commonProps,
                    originX: 'center',
                    originY: 'center',
                    stroke: 'red',
                    strokeWidth: 2,
                    fill: '',
                });

                const inner = new fabric.Ellipse({
                    left: x,
                    top: y,
                    rx: 0,
                    ry: 0,
                    ...commonProps,
                    originX: 'center',
                    originY: 'center',
                    stroke: 'green',
                    strokeWidth: 2,
                    fill: '',
                });

                return new fabric.Group([outer, inner], {
                    left: x,
                    top: y,
                    originX: 'center',
                    originY: 'center',
                    selectable: false
                });
            case 'cross':
                const line1 = new fabric.Line([x - 10, y - 10, x + 10, y + 10], { stroke: color, strokeWidth: 2, selectable: false });
                const line2 = new fabric.Line([x + 10, y - 10, x - 10, y + 10], { stroke: color, strokeWidth: 2, selectable: false });
                return new fabric.Group([line1, line2], { left: x, top: y, selectable: false });
            case 'greenArrow':
                return new fabric.Path('M 0 40 L 20 0 L 40 40', {
                    left: x,
                    top: y,
                    fill: '',
                    stroke: '#00FF00',
                    strokeWidth: 2,
                    selectable: false,
                    scaleX: 0,
                    scaleY: 0
                });
            case 'blackArrow':
                return new fabric.Path('M 0 40 L 20 0 L 40 40', {
                    left: x,
                    top: y,
                    fill: '',
                    stroke: '#000000',
                    strokeWidth: 2,
                    selectable: false,
                    scaleX: 0,
                    scaleY: 0
                });
            case 'redArrow':
                return new fabric.Path('M 0 40 L 20 0 L 40 40', {
                    left: x,
                    top: y,
                    fill: '',
                    stroke: '#FF0000',
                    strokeWidth: 2,
                    selectable: false,
                    scaleX: 0,
                    scaleY: 0
                });
            case 'chevronDouble':
                const chevron1 = new fabric.Path('M 0 10 L 10 0 L 20 10', {
                    left: 0,
                    top: 0,
                    fill: '',
                    stroke: 'Red',
                    originX: 'center',
                    strokeWidth: 2,
                    selectable: false
                });
                const chevron2 = new fabric.Path('M 0 10 L 10 0 L 20 10', {
                    left: 0,
                    top: 14,
                    fill: '',
                    stroke: 'Green',
                    originX: 'center',
                    strokeWidth: 2,
                    selectable: false
                });
                return new fabric.Group([chevron1, chevron2], {
                    left: x,
                    top: y,
                    selectable: false
                });
            default:
                return null;
        }
    }

    function updateShape(tool, shape, pointer) {
        if (!shape) return;
        const dx = pointer.x - origX;
        const dy = pointer.y - origY;

        switch (tool) {
            case 'rectangle':
                shape.set({ width: dx, height: dy });
                break;
            case 'circle':
                shape.set({ rx: Math.abs(dx) / 2, ry: Math.abs(dy) / 2 });
                break;
            case 'line':
                shape.set({ x2: pointer.x, y2: pointer.y });
                break;
            case 'dot':
                shape.set({ radius: Math.max(Math.abs(dx), Math.abs(dy)) / 10 });
                break;
            case 'dotCircle':
                while (shape._objects.length > 0) {
                    shape.remove(shape._objects[0]);
                }
                const radius = Math.min(Math.max(Math.abs(dx), Math.abs(dy)) / 2, 200);
                const dotCount = 36;
                const dotRadius = 2;
                shape.set({ left: origX, top: origY });
                for (let i = 0; i < dotCount; i++) {
                    const angle = (i * 2 * Math.PI) / dotCount;
                    const x = radius * Math.cos(angle);
                    const y = radius * Math.sin(angle);
                    const dot = new fabric.Circle({
                        left: x,
                        top: y,
                        radius: dotRadius,
                        fill: color,
                        selectable: false,
                        originX: 'center',
                        originY: 'center'
                    });
                    shape.addWithUpdate(dot);
                }
                shape.setCoords();
                const canvasWidth = canvas.getWidth();
                const canvasHeight = canvas.getHeight();
                const groupBounds = shape.getBoundingRect();
                if (groupBounds.left < 0) shape.set({ left: origX + radius });
                if (groupBounds.top < 0) shape.set({ top: origY + radius });
                if (groupBounds.left + groupBounds.width > canvasWidth) shape.set({ left: origX - radius });
                if (groupBounds.top + groupBounds.height > canvasHeight) shape.set({ top: origY - radius });
                break;
            case 'ellipseInEllipse':
                const outer = shape._objects[0];
                const inner = shape._objects[1];
                const rx = Math.abs(dx) / 2;
                const ry = Math.abs(dy) / 3;
                outer.set({ rx: rx, ry: ry });
                inner.set({ rx: rx * 0.6, ry: ry * 0.6 });
                break;
            case 'cross':
                const line1 = shape._objects[0];
                const line2 = shape._objects[1];
                const size = Math.max(Math.abs(dx), Math.abs(dy)) / 2;
                line1.set({ x1: origX - size, y1: origY - size, x2: origX + size, y2: origY + size });
                line2.set({ x1: origX + size, y1: origY - size, x2: origX - size, y2: origY + size });
                break;
            case 'greenArrow':
            case 'blackArrow':
            case 'redArrow':
                shape.set({ scaleX: Math.abs(dx) / 40, scaleY: Math.abs(dy) / 40 });
                break;
            case 'chevronDouble':
                const chevron1 = shape._objects[0];
                const chevron2 = shape._objects[1];
                chevron1.set({ scaleX: Math.abs(dx) / 40, scaleY: Math.abs(dy) / 40 });
                chevron2.set({ scaleX: Math.abs(dx) / 40, scaleY: Math.abs(dy) / 40 });
                break;
        }
        shape.setCoords();
        canvas.renderAll();
    }

    function fillColor(e) {
        const pointer = canvas.getPointer(e);
        const target = canvas.findTarget(e, false);

        if (target && target.type !== 'group') {
            target.set('fill', color);
            canvas.renderAll();
            saveCanvasState();
        } else if (target && target.type === 'group') {
            target._objects.forEach(obj => obj.set('fill', color));
            canvas.renderAll();
            saveCanvasState();
        } else {
            const fillRect = new fabric.Rect({
                left: 0,
                top: 0,
                width: canvas.width,
                height: canvas.height,
                fill: color,
                selectable: false,
                evented: false
            });
            canvas.add(fillRect);
            canvas.sendToBack(fillRect);
            if (backgroundImage) {
                canvas.sendToBack(fillRect);
            }
            canvas.renderAll();
            saveCanvasState();
        }
    }

    function prepareCanvasDownload() {
        try {
            const dataURL = canvas.toDataURL({
                format: 'png',
                quality: 1
            });
            document.getElementById('CanvasDataURL').value = dataURL;
            return true; 
        } catch (e) {
            console.error('Error preparing canvas for download:', e);
            return false; 
        }
    }

    canvas.on('mouse:down', function (opt) {
        if (currentTool === 'fill') {
            fillColor(opt.e);
            return;
        }
        if (!['rectangle', 'circle', 'line', 'dot', 'dotCircle', 'ellipseInEllipse', 'cross', 'greenArrow', 'blackArrow', 'redArrow', 'chevronDouble'].includes(currentTool)) return;

        isDrawing = true;
        const pointer = canvas.getPointer(opt.e);
        origX = pointer.x;
        origY = pointer.y;
        shape = createShape(currentTool, origX, origY);
        if (shape) canvas.add(shape);
    });

    canvas.on('mouse:move', function (opt) {
        if (!isDrawing || !shape) return;
        const pointer = canvas.getPointer(opt.e);
        updateShape(currentTool, shape, pointer);
    });

    canvas.on('mouse:up', function () {
        if (shape) {
            shape.setCoords();
            canvas.renderAll();
            saveCanvasState();
        }
        isDrawing = false;
        shape = null;
    });

    canvas.on('path:created', function () {
        saveCanvasState();
    });

    canvas.on('object:modified', function () {
        saveCanvasState();
    });

    window.onload = function () {
        const imagePath = document.getElementById('UploadedImagePath').value;
        if (imagePath) {
            fabric.Image.fromURL(imagePath, function (img) {
                const scaleX = canvas.width / img.width;
                const scaleY = canvas.height / img.height;
                canvas.setBackgroundImage(img, canvas.renderAll.bind(canvas), { scaleX, scaleY });
                backgroundImage = img;
                saveCanvasState();
            }, { crossOrigin: 'anonymous' });
        } else {
            saveCanvasState();
        }
    };
</script>

</body>
</html>