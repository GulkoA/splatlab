%% SplatLab
% Developed by Alex Gulko in 2022
% Software Design Project for Engineering 1181 at The Ohio State University
% https://l.gulko.net/splatlab

%% Clear workspace and command window
clear
clc

%% Init important params
global hdef
global vdef

hdef = 500;
vdef = 300;

%% Load images
global images
images = zeros(1, 75, 75, 3);
images(1, :, :, :) = imread('michigan-footall-player-pixel.png') ./ 255;
images(2, :, :, :) = imread('game-over.png') ./ 255;
images(3, :, :, :) = imread("game-title-menu.png") ./ 255;
images(4, :, :, :) = imread('defeat-michigan.png') ./ 255;


%% Open and set up figure
global renderFigure
renderFigure = figure(1);
renderFigure.Name = 'SplatLab';
set(renderFigure,'KeyPressFcn',@keyPressHandler);

%% Draw menu
titleScreen()

function titleScreen()
    global score
    global vdef
    global hdef
    global images
    img = ones(vdef, hdef, 3);
    img(vdef/2-37:vdef/2+37, hdef/2-37:hdef/2+37, :) = images(3, :, :, :);
    image(img)
    controls = "Use wasd to move, arrow keys left/right to rotate, and space for spraying red paint";
    text(10, vdef*0.75, controls);
    score = 0;
end

function startGame()
    %% Init parameters
    global hdef
    global vdef
    global map;
    global mapSize;
    global fov;
    global playerPos
    global playerRot
    global heightMod
    global maxLength
    global img
    global floorColor
    global skyColor
    global wallTypeColor
    global maxShootingRange
    global enemiesAmount
    global radiusPaintDamage
    global radiusEnemyPaint
    global enemiesPosRot
    global score

    % Rendering parameters
    fov = 1.1;
    heightMod = 1;
    
    % Map parameters
    mapSize = 100;
    playerPos = [mapSize / 2, mapSize / 2];
    % Player rotation in radians
    playerRot = 0;
    
    % Plotting parameters
    
    floorColor = [34, 34, 34] ./ 255;
    skyColor = [176, 214, 255] ./ 255;
    
    wallTypeColor = [[56, 56, 56]; [219, 219, 219]; [187, 0, 0]; [255, 203, 5]] ./ 255;
    
    img = zeros(vdef, hdef, 3);
    
    % Game parameters
    maxShootingRange = 40;
    
    radiusPaintDamage = 4;

    radiusEnemyPaint = 5;

    enemiesAmount = 4;
    enemiesPosRot = randi(mapSize, enemiesAmount, 2);
    enemiesPosRot(:, 3) = zeros(enemiesAmount, 1);

    score = 100;


    %% Init map
    map = rand(mapSize);
    for x = 1:length(map(:, 1))
        for y = 1:length(map(1, :))
            if x == 1 || x == length(map(:, 1)) || y == 1 || y == length(map(1, :))
                map(y, x) = 1;
            elseif (map(y, x) * 3 + map(y-1, x) + map(y+1, x) + map(y, x-1) + map(y, x+1)) > 4.7
                map(y, x) = 2;
            else
                map(y, x) = 0;
            end
        end
    end

    map(playerPos(1)-10:playerPos(1)+10, playerPos(1)-10:playerPos(1)+10) = zeros(21);
    maxLength = sqrt(length(map(1, :))^2 + (length(map(:, 1)))^2);

    %% Init enemies
    for i = 1:enemiesAmount
        while map(enemiesPosRot(i, 1), enemiesPosRot(i, 2)) > 0
            enemiesPosRot(i, 1:2) = randi(mapSize, 2, 1);
        end
    end
    
    %% Start first render
    render()
end

function keyPressHandler(~,event)

    global playerRot
    global fov
    global score
    global enemiesPosRot
%     event.Key;
    if score > 0 && score < 999
        switch event.Key
            case 'w'
               movePlayer(cos(playerRot), sin(playerRot));
               chackPlayerDamage()
               moveEnemies()
            case 's'
                movePlayer(-cos(playerRot), -sin(playerRot));
                chackPlayerDamage()
                moveEnemies()
            case 'a'
               movePlayer(sin(playerRot), -cos(playerRot));
               chackPlayerDamage()
               moveEnemies()
            case 'd'
              movePlayer(-sin(playerRot), cos(playerRot));
              chackPlayerDamage()
              moveEnemies()
            case 'leftarrow'
               playerRot = playerRot - 0.1;
            case 'rightarrow'
                playerRot = playerRot + 0.1;
            case 'downarrow'
                fov = fov - 0.1;
            case 'uparrow'
               fov = fov + 0.1;
            case 'space'
               shoot();
               checkEnemyDamage();
               moveEnemies();
            case 'comma'
                playerRot = playerRot - pi/2;
            case 'period'
                playerRot = playerRot + pi/2;
        end
        render()
        if score <=0
            gameOver();
        elseif score > 999
            winScreen()
        end
    elseif event.Key == 'space'
        startGame()
    end

end

function movePlayer(xAdd, yAdd)
    global playerPos;
    global map;
    finalPos = [playerPos(1) + yAdd, playerPos(2) + xAdd];
    if map(round(finalPos(1)), round(playerPos(2))) < 1
        playerPos(1) = finalPos(1);
    end
    if map(round(playerPos(1)), round(finalPos(2))) < 1
        playerPos(2) = finalPos(2);
    end
end

function shoot()
    global map
    global rayPoses
    global rayLengths
    global rayWallCollidedTypes
    global hdef
    global maxShootingRange
    for x = floor(hdef / 4) : ceil(3 * hdef / 4)
        if rayLengths(x) < maxShootingRange
            if rayWallCollidedTypes(x) <= 4
                map(round(rayPoses(x, 1)), round(rayPoses(x, 2))) = 3;
            end
        end
    end
end

% function moveEnemies()
%     global enemiesPosRot
%     global enemiesAmount
% end

function checkEnemyDamage()
    global mapSize
    global map
    global enemiesPosRot
    global enemiesAmount
    global radiusPaintDamage

    for i=1:enemiesAmount
        pos = enemiesPosRot(i, :);
        squareLeft = pos(1) - radiusPaintDamage;
        squareRight = pos(1) + radiusPaintDamage;
        if squareLeft < 1
            squareLeft = 1;
        elseif squareRight > mapSize
            squareRight = mapSize;
        end

        squareTop = pos(2) + radiusPaintDamage;
        squareBottom = pos(2) - radiusPaintDamage;
        if squareBottom < 1
            squareBottom = 1;
        elseif squareTop > mapSize
            squareTop = mapSize;
        end

        for x=squareLeft:squareRight
            for y=squareBottom:squareTop
                if map(x, y) == 3
                    killEnemy(i);
                    break;
                end
            end
        end
    end
end

function winScreen()
    global images
    global hdef
    global vdef
    img = ones(vdef, hdef, 3);
    img(vdef/2-37:vdef/2+37, hdef/2-37:hdef/2+37, :) = images(4, :, :, :);
    image(img)
end

function chackPlayerDamage()
    global mapSize
    global map
    global playerPos
    global radiusPaintDamage

       
        squareLeft = round(playerPos(1)) - radiusPaintDamage;
        squareRight = round(playerPos(1)) + radiusPaintDamage;
        if squareLeft < 1
            squareLeft = 1;
        elseif squareRight > mapSize
            squareRight = mapSize;
        end

        squareTop = round(playerPos(2)) + radiusPaintDamage;
        squareBottom = round(playerPos(2)) - radiusPaintDamage;
        if squareBottom < 1
            squareBottom = 1;
        elseif squareTop > mapSize
            squareTop = mapSize;
        end

        for x=squareLeft:squareRight
            for y=squareBottom:squareTop
                if map(x, y) == 4
                    damagePlayer();
                end
            end
        end
end

function killEnemy(enemyId)
    global score
    global enemiesPosRot
    enemiesPosRot(enemyId, :) = [0, 0, 0];
    score = score + 25;
    if sum(enemiesPosRot(:, :, :)) == 0
        score = 1000;
    end
end

function damagePlayer()
    global score
    score = score - 1;
end

function gameOver()
    global images
    global hdef
    global vdef
    img = ones(vdef, hdef, 3);
    img(vdef/2-37:vdef/2+37, hdef/2-37:hdef/2+37, :) = images(2, :, :, :);
    image(img)
end
    

function moveEnemies()
    global enemiesPosRot
    global enemiesAmount
    global radiusEnemyPaint
    global mapSize
    global map

    for i=1:enemiesAmount
        if enemiesPosRot(i, 1) ~= 0
            xChange = randi(3) - 2;
            yChange = randi(3) - 2;
            finalPos = [enemiesPosRot(i, 1) + xChange, enemiesPosRot(i, 2) + yChange];
            if finalPos(1) > 0 && finalPos(1) < mapSize && map(finalPos(1), enemiesPosRot(i, 2)) < 1
                enemiesPosRot(i, 1) = finalPos(1);
            end
            if finalPos(2) > 0 && finalPos(2) < mapSize && map(enemiesPosRot(i, 1), finalPos(2)) < 1
                enemiesPosRot(i, 2) = finalPos(2);
            end
            
            pos = enemiesPosRot(i, :);
            squareLeft = pos(1) - radiusEnemyPaint;
            squareRight = pos(1) + radiusEnemyPaint;
            if squareLeft < 1
                squareLeft = 1;
            elseif squareRight > mapSize
                squareRight = mapSize;
            end
    
            squareTop = pos(2) + radiusEnemyPaint;
            squareBottom = pos(2) - radiusEnemyPaint;
            if squareBottom < 1
                squareBottom = 1;
            elseif squareTop > mapSize
                squareTop = mapSize;
            end
    
            for x=squareLeft:squareRight
                for y=squareBottom:squareTop
                    if rand > 0.2 && map(x, y) > 0 && map(x, y) < 3
                        map(x, y) = 4;
                    end
                end
            end
        end
    end
    checkEnemyDamage();
end

function render()
     global images

     global map
     global mapSize
     global playerPos
     global playerRot
     global hdef
     global vdef
     global fov
     global heightMod
     global maxLength
     global img
     global floorColor
     global skyColor
     global wallTypeColor
     global rayLengths
     global rayPoses

     global rayWallCollidedTypes
     global enemiesPosRot
     global enemiesAmount
     global score
     %% Rendering
     tic
     directions = 0:(hdef - 1);
     angles = (directions - (hdef / 2)) / (2 * hdef) .* fov + playerRot;
     img = zeros(vdef, hdef, 3);
     rayPoses = zeros(hdef, 2);
     rayWallCollidedTypes = zeros(hdef, 1);
     imagesOverlay = zeros(vdef, hdef, 3);

     enemiesFaced = ones(enemiesAmount);
     for x = 1:hdef
        rayPos = playerPos;
        angle = mod(angles(x), 2*pi);
        % ray up
        if angle > pi/4 && angle < 3*pi/4
            xAdd = cot(angle);
            yAdd = 1;
         % ray down
        elseif angle >= 5*pi/4 && angle <= 7*pi/4
            xAdd = -cot(angle);
            yAdd = -1;
        % ray right
        elseif angle <= pi/4 || angle >= 7*pi/4
            xAdd = 1;
            yAdd = tan(angle);
        % ray left
        else
            xAdd = -1;
            yAdd = -tan(angle);
        end
        wallFaced = 0;
        enemyFaced = 0;
        while wallFaced < 1
            rayPos(1) = rayPos(1) + yAdd;
            rayPos(2) = rayPos(2) + xAdd;
            enemyFaced = enemyAtPos(round(rayPos(1)), round(rayPos(2)));
            if enemyFaced > 0 && x > 38 && x < hdef - 38 && enemiesFaced(enemyFaced)
                enemiesFaced(enemyFaced) = 0;
                wallFaced = 10;
                break;
            end
            wallFaced = map(round(rayPos(1)), round(rayPos(2)));
        end

        rayLength = sqrt((rayPos(1) - playerPos(1))^2 + (rayPos(2) - playerPos(2))^2);

        % save ray info to global variables (used for paint spraying mechanic)
        rayPoses(x, :) = rayPos(:);
        rayLengths(x) = rayLength;
        rayWallCollidedTypes(x) = wallFaced;
        
        %% Drawing
        % height of the column from 0 to 1
        heightDec = 1 - (rayLength / maxLength);
        if heightDec < 0
            heightDec = 0;
        end
        height = floor(heightDec * vdef * heightMod);
        margin = floor((vdef - height) / 2);

        if enemyFaced > 0 && ~enemiesFaced(enemyFaced) % && x > 75 && x < hdef - 75
            imagesOverlay(round(margin+height)-74:round(margin+height), x-37:x+37, :) = images(1, :, :, :);
        else
             for y = 0:margin
                img(y + 1, x, :) = skyColor;
             end
             wallColor = heightDec^3 * 2 .* wallTypeColor(wallFaced, :);
             for y = margin:margin+height
                 img(y + 1, x, :) = wallColor;
             end
             for y = margin+height:vdef
                img(y+1, x, :) = floorColor;
             end
        end
     end
     renderTime = toc;
     tic;
     %% Plotting img and map
     figure(1)
    
     for imgX = 1:hdef
         for imgY = 1:vdef
             if any(imagesOverlay(imgY, imgX, :) > 0)
                 img(imgY, imgX, :) = imagesOverlay(imgY, imgX, :);
             end
         end
     end

     mapWithOverlay = zeros(mapSize, mapSize, 3);

     for x = 1:mapSize
         for y = 1:mapSize
             mapWithOverlay(y, x, :) = mapColor(map(y, x));
         end
     end

     mapWithOverlay(round(playerPos(1)), round(playerPos(2)), :) = wallTypeColor(3, :);

     for i = 1:length(enemiesPosRot)
         if enemiesPosRot(i, 1) ~= 0
            mapWithOverlay(enemiesPosRot(i, 1), enemiesPosRot(i, 2), :) = wallTypeColor(4, :);
         end
     end


     img(1:mapSize, 1:mapSize, :) = mapWithOverlay;
     image(img);

     line([playerPos(2), rayPoses(hdef/2, 2)], [playerPos(1), rayPoses(hdef/2, 1)])

     plotTime = toc;
     fps = 1/(renderTime + plotTime);
     xlabel("Fps: " + fps + " Render time: " + renderTime + " Plotting time: " + plotTime);
     title("Score: " + score);
    
end

function index = enemyAtPos(y, x)
    global enemiesPosRot
    index = 0;
    for i = 1:length(enemiesPosRot)
        enemiesPosRot(i, 1:2);
        if enemiesPosRot(i, 1) ~= 0 && isequal(enemiesPosRot(i, 1:2), [y x])
            index = i;
            break
        end
    end
end

function color = mapColor(wallType)
    global wallTypeColor
    if wallType < 1
        color = [0, 0, 0];
    else
        color = wallTypeColor(wallType, :);
    end
end