classdef MATLABcaster < handle
  
  properties
    gameTimer;
    tick = 0.05;
    game;
    ax;
    map = [ 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2 2;
            1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
            1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
            1 0 0 0 0 0 0 0 0 0 0 0 0 0 0 1;
            1 1 1 1 0 0 0 0 0 0 0 0 0 0 0 1;
            1 0 1 2 2 0 0 0 0 0 0 0 0 0 0 1;
            1 0 2 0 0 0 2 1 1 2 0 0 0 0 0 1;
            1 0 2 0 1 0 1 0 0 1 0 0 0 0 0 1;
            1 0 2 0 0 0 1 0 0 1 0 0 0 0 0 1;
            1 0 1 0 2 1 2 2 0 1 0 0 0 0 0 1;
            1 0 0 0 1 0 0 0 0 2 0 0 0 0 0 1;
            1 1 2 0 1 0 1 0 2 1 2 0 0 0 0 1;
            1 0 0 0 1 0 1 0 1 0 1 0 0 0 0 1;
            1 0 2 1 2 0 1 0 2 0 1 0 0 0 0 1;
            2 0 0 0 0 0 2 0 0 0 1 0 0 0 0 1;
            1 2 1 1 1 2 1 1 1 1 1 1 1 1 1 1];
    mapHeight;
    mapWidth;
    flippedMap;
    wallSize = 8;
    vertHit;
    horHit;
    wood = imread('pics/wood.png');%1
    greystone = imread('pics/greystone.png')%2
    txtNum;
    screen = zeros(480,640,3);
    screenHeight = 480;
    screenWidth = 640;
    screenCopy;
    display;
    angle;
    angleDiff;
    step = 1.2;
    
    black = [0 0 0];
    white = [1 1 1];
    yellow = [1 1 0];
    darkYellow = [0.5, 0.5, 0];
    brown = [107/255, 65/255, 0];
    skyBlue = [158/255, 171/255, 255/255];
    bgColor;
    hit;
    playerPos;
    playerAngle = pi*0.1;
    fieldOfVision = pi/3;
    rayAngle;
    oneDegree = pi/180;
    dist;
    shadow;
    limitConst = 2000;
    
    keys = {'w','a','d','s','escape','space','e','q'};
    keyStatus = false(1,8);
    
    up = 1;
    left = 2;
    right = 3;
    down = 4;
    escape = 5;
    space = 6;
    e = 7;
    q = 8;
  end
  
  methods
    function this = MATLABcaster()
      this.gameTimer = timer;
      this.gameTimer.StartFcn = @this.introFcn;
      this.gameTimer.TimerFcn = @this.gameFcn;
      this.gameTimer.StopFcn = @this.endFcn;
      this.gameTimer.Period = this.tick;
      this.gameTimer.ExecutionMode = 'fixedRate';
      
      start(this.gameTimer);
    end
    
    function introFcn(this, ~, ~)
      this.game = figure('KeyPressFcn',{@this.KeySniffFcn},...
        'KeyReleaseFcn',{@this.KeyRelFcn},...
        'CloseRequestFcn',{@this.QuitFcn},...
        'menubar', 'none',...
        'NumberTitle', 'off',...
        'WindowState', 'maximized');
      this.ax = axes(this.game);
      this.ax.XLim = [0, this.screenWidth];
      this.ax.YLim = [0, this.screenHeight];
      this.ax.Position = [0 0 1 1];
      this.ax.XTick = [];
      this.ax.YTick = [];
      %axis equal;
      
      this.wood = double(this.wood)./255;
      this.greystone = double(this.greystone)./255;
      this.flippedMap = flip(this.map);
      
      this.screen(this.screenHeight/2:this.screenHeight,:,1) = this.skyBlue(1);
      this.screen(this.screenHeight/2:this.screenHeight,:,2) = this.skyBlue(2);
      this.screen(this.screenHeight/2:this.screenHeight,:,3) = this.skyBlue(3);
      this.screen(1:this.screenHeight/2,:,1) = this.brown(1);
      this.screen(1:this.screenHeight/2,:,2) = this.brown(2);
      this.screen(1:this.screenHeight/2,:,3) = this.brown(3);
      
      this.mapHeight = size(this.map,2);
      this.mapWidth = size(this.map,1);
      this.playerPos = [this.mapWidth*this.wallSize/2, this.mapHeight*this.wallSize/2];
%       this.playerPos = [87.969235232803130,63.531959733904365];
%       this.playerAngle = 5.338159265358979;
      this.screenCopy = this.screen;
      this.display = image('CData', this.screen);
    end
    
    
    function gameFcn(this, ~, ~)
      this.movePlayer();
      this.drawRays();
      
      this.display.CData = this.screen;
      this.quitGame();
    end
    
    
    
    function endFcn(~, ~, ~)
      listOfTimers = timerfindall;
      if ~isempty(listOfTimers)
        stop(listOfTimers);
        delete(listOfTimers);
      end
      close all
    end
    
    function drawMap(this, ~, ~)
      for x = 1:size(this.map, 1)
        for y = 1:size(this.map, 2)
          %draw one square of the map
          for xx = (2 + (x-1)*this.screenWidth/size(this.map, 1)):(this.screenWidth/size(this.map, 1) + (x-1)*this.screenWidth/size(this.map, 1)-1)
            for yy = (2 + (y-1)*this.screenHeight/size(this.map, 2)):(this.screenHeight/size(this.map, 2) + (y-1)*this.screenHeight/size(this.map, 2)-1)
              if this.map(x,y) == 1
                this.screen(yy,xx,1:3) = this.white;
              else
                this.screen(yy,xx,1:3) = this.black;
              end
            end
          end
        end
      end
    end
    
    function drawPlayer(this, ~, ~)
      for x = this.playerPos(1):this.playerPos(1) + 1
        for y = this.playerPos(2):this.playerPos(2) + 1
          this.screen(y,x,1:3) = this.yellow;
        end
      end
    end
    
    function movePlayer(this, ~, ~)
      previousPos = [this.playerPos(1),this.playerPos(2)];
      
      if (this.keyStatus(this.right))
        this.playerAngle = this.playerAngle + 6.28/60;
        if this.playerAngle > 2*pi
          this.playerAngle = this.playerAngle-2*pi;
        end
      end
      if (this.keyStatus(this.left))
        this.playerAngle = this.playerAngle - 6.28/60;
        if this.playerAngle < 0
          this.playerAngle = 2*pi+this.playerAngle;
        end
      end
      if (this.keyStatus(this.up))
        this.playerPos(1) = this.playerPos(1) + cos(this.playerAngle)*this.step;
        this.playerPos(2) = this.playerPos(2) + sin(this.playerAngle)*this.step;
      end
      if (this.keyStatus(this.down))
        this.playerPos(1) = this.playerPos(1) - cos(this.playerAngle)*this.step;
        this.playerPos(2) = this.playerPos(2) - sin(this.playerAngle)*this.step;
      end
      if (this.keyStatus(this.e))
        this.playerPos(1) = this.playerPos(1) + cos(this.playerAngle+pi/2)*this.step;
        this.playerPos(2) = this.playerPos(2) + sin(this.playerAngle+pi/2)*this.step;
      end
      if (this.keyStatus(this.q))
        this.playerPos(1) = this.playerPos(1) - cos(this.playerAngle+pi/2)*this.step;
        this.playerPos(2) = this.playerPos(2) - sin(this.playerAngle+pi/2)*this.step;
      end
      %collision system
      if this.map(ceil(this.playerPos(2)/this.wallSize), ceil(this.playerPos(1)/this.wallSize)) > 0
        if this.map(ceil(this.playerPos(2)/this.wallSize), ceil(previousPos(1)/this.wallSize)) > 0 
          this.playerPos(2) = previousPos(2);
        end
        if this.map(ceil(previousPos(2)/this.wallSize), ceil(this.playerPos(1)/this.wallSize)) > 0
          this.playerPos(1) = previousPos(1);
        end
      end
    end
    
    function clearMap(this,~,~)
      for x = this.playerPos(1):this.playerPos(1)+2
        for y = this.playerPos(2):this.playerPos(2)+2
          this.screen(y,x,1:3) = this.screenCopy(y,x,1:3);
        end
      end
    end
    
    function drawRays(this,~,~)
      %This function casts rays and calculates where they hit and how long
      %they are
      this.screen = this.screenCopy;
      this.rayAngle = this.playerAngle-this.fieldOfVision/2;
      for currentAngle = 1:this.screenWidth
        if this.rayAngle < 0
          this.rayAngle = 2*pi+this.rayAngle;
        end
        if this.rayAngle > 2*pi
          this.rayAngle = this.rayAngle-2*pi;
        end
        
        %check horizontal lines
        if this.rayAngle == 0 %looking straight right
          yHit = this.playerPos(2);
          xHit = ceil(this.playerPos(1))*this.wallSize;
        end
        if this.rayAngle == pi %looking straight left
          yHit = this.playerPos(2);
          xHit = floor(this.playerPos(1))*this.wallSize;
        end
        if this.rayAngle > pi %looking down
          yHit = floor(this.playerPos(2)/this.wallSize)*this.wallSize;
          xHit = this.playerPos(1) + (this.playerPos(2) - yHit)/-tan(this.rayAngle);
        end
        if this.rayAngle < pi %looking up
          yHit = ceil(this.playerPos(2)/this.wallSize)*this.wallSize;
          xHit = this.playerPos(1) + (yHit - this.playerPos(2))/tan(this.rayAngle);
        end
        
        for i = 1:100
          if xHit < 1
            xHit = 1;
          end
          if xHit > this.mapWidth*this.wallSize
            xHit = this.mapWidth*this.wallSize;
          end
          
          if this.map(yHit/this.wallSize+1, ceil(xHit/this.wallSize)) > 0 && this.rayAngle < pi
            horTxt = this.map(yHit/this.wallSize+1, ceil(xHit/this.wallSize));
            break
          elseif this.map(yHit/this.wallSize, ceil(xHit/this.wallSize)) > 0 && this.rayAngle > pi
            horTxt = this.map(yHit/this.wallSize, ceil(xHit/this.wallSize));
            break
          else
            if this.rayAngle == 0
              xHit = xHit + this.wallSize;
              if xHit > this.mapWidth*this.wallSize
                xHit = this.mapWidth*this.wallSize;
              end
            end
            if this.rayAngle == pi
              xHit = xHit - 16;
              if xHit < 1
                xHit = 1;
              end
            end
            if this.rayAngle > pi
              yHit = yHit - this.wallSize;
              xHit = xHit + this.wallSize/-tan(this.rayAngle);
            end
            if this.rayAngle < pi
              yHit = yHit + this.wallSize;
              xHit = xHit + this.wallSize/tan(this.rayAngle);
            end
          end
        end
        %calculates where exactly was the wall hit (plotting purposes)
        this.horHit = xHit - floor(xHit/this.wallSize)*this.wallSize;
        %pythagorean theorem to calculate the lenght of the ray
        horizontalDist = sqrt((this.playerPos(1)-xHit)^2+(this.playerPos(2)-yHit)^2);
        
        %check vertical lines
        if this.rayAngle == pi/2 %looking straight up
          xHit = this.playerPos(1);
          yHit = ceil(this.playerPos(2))*this.wallSize;
        end
        if this.rayAngle == 3*pi/2 %looking straight down
          xHit = this.playerPos(1);
          yHit = floor(this.playerPos(2))*this.wallSize;
        end
        if this.rayAngle > pi/2 && this.rayAngle < 3*pi/2
          xHit = floor(this.playerPos(1)/this.wallSize)*this.wallSize;
          yHit = this.playerPos(2) + (this.playerPos(1) - xHit)*-tan(this.rayAngle);
        end
        if this.rayAngle < pi/2 || this.rayAngle > 3*pi/2
          xHit = ceil(this.playerPos(1)/this.wallSize)*this.wallSize;
          yHit = this.playerPos(2) + (xHit - this.playerPos(1))*tan(this.rayAngle);
        end
        
        for i = 1:100 %enough loops to reach the wall
          if yHit < 1 %limits
            yHit = 1;
          end
          if yHit > this.mapHeight*this.wallSize
            yHit = this.mapHeight*this.wallSize;
          end
          
          if this.map(ceil(yHit/this.wallSize), xHit/this.wallSize+1) > 0 && (this.rayAngle > 3*pi/2 || this.rayAngle < pi/2)
            vertTxt = this.map(ceil(yHit/this.wallSize), xHit/this.wallSize+1); %remember the texture type on ray hit
            break
          elseif this.map(ceil(yHit/this.wallSize), xHit/this.wallSize) > 0 && (this.rayAngle > pi/2 && this.rayAngle < 3*pi/2)
            vertTxt = this.map(ceil(yHit/this.wallSize), xHit/this.wallSize);
            break
          else
            if this.rayAngle == pi/2 %looking straight up
              yHit = yHit + this.wallSize;
              if yHit > this.screenHeight
                yHit = this.screenHeight;
              end
            end
            if this.rayAngle == 3*pi/2 %looking straight down
              yHit = yHit - this.wallSize;
              if yHit < 1
                yHit = 1;
              end
            end
            if this.rayAngle > pi/2 && this.rayAngle < 3*pi/2 %looking left
              xHit = xHit - this.wallSize;
              yHit = yHit + (this.wallSize)*-tan(this.rayAngle);
            end
            if this.rayAngle > 3*pi/2 || this.rayAngle < pi/2 %looking right
              xHit = xHit + this.wallSize;
              yHit = yHit + (this.wallSize)*tan(this.rayAngle);
            end
          end
        end
        this.vertHit = yHit - floor(yHit/this.wallSize)*this.wallSize; 
        %pythagorean theorem to calculate the lenght of the ray
        verticalDist = sqrt((this.playerPos(1)-xHit)^2+(this.playerPos(2)-yHit)^2); 

        if horizontalDist < verticalDist %check which ray is longer
          this.dist = horizontalDist;
          this.hit = this.horHit;
          this.txtNum = horTxt;
          this.shadow = 1; %if horizontalRay is longer, theres a shadow
        else
          this.dist = verticalDist;
          this.hit = this.vertHit;
          this.txtNum = vertTxt;
          this.shadow = 0;
        end
        this.angle = currentAngle;
        this.angleDiff = this.playerAngle - this.rayAngle;
        if this.angleDiff < 0
          this.angleDiff = this.angleDiff + 2*pi;
        end
        if this.angleDiff > 2*pi
          this.angleDiff = this.angleDiff - 2*pi;
        end
        this.dist = this.dist*cos(this.angleDiff);
        this.drawWall();
        this.rayAngle = this.rayAngle + this.fieldOfVision/this.screenWidth;
      end
    end
    
    function drawWall(this,~,~)
      bottomLine = this.screenHeight/2-round(this.screenHeight*3/this.dist);
      topLine = this.screenHeight/2+round(this.screenHeight*3/this.dist);
      if bottomLine < -this.limitConst+this.screenHeight/2%optimisation limits
        bottomLine = -this.limitConst+this.screenHeight/2;
      end
      if topLine > this.limitConst+this.screenHeight/2
        topLine = this.limitConst+this.screenHeight/2;
      end
      
      wallPiece = round(linspace(1,size(this.wood,1),topLine - bottomLine));
      if size(wallPiece,2) > this.screenHeight
        wallPiece = wallPiece(:,-bottomLine+1:topLine,:);
        bottomLine = 0;
        topLine = this.screenHeight;
      end
      
      switch this.txtNum
        case 1%wood
          stretchedTxt(:,1,1:3) = this.wood(wallPiece,ceil(this.hit*size(this.wood,1)/this.wallSize),1:3);
          if this.shadow == 1
            this.screen(bottomLine+1:topLine,this.angle,1:3) = stretchedTxt.*0.6;
          elseif this.shadow == 0
            this.screen(bottomLine+1:topLine,this.angle,1:3) = stretchedTxt;
          end
        case 2 %greystone
          stretchedTxt(:,1,1:3) = this.greystone(wallPiece,ceil(this.hit*size(this.wood,1)/this.wallSize),1:3);
          if this.shadow == 1
            this.screen(bottomLine+1:topLine,this.angle,1:3) = stretchedTxt.*0.6;
          elseif this.shadow == 0
            this.screen(bottomLine+1:topLine,this.angle,1:3) = stretchedTxt;
          end
      end
    end
    
    function KeySniffFcn(this,~,event)
      key = event.Key;
      this.keyStatus = (strcmp(key, this.keys) | this.keyStatus);
    end
    
    function KeyRelFcn(this,~,event)
      key = event.Key;
      this.keyStatus = (~strcmp(key, this.keys) & this.keyStatus);
    end
    function quitGame(this) %quit the game when esc is pressed or figure is closed
      if ~ishghandle(this.game) || this.keyStatus(this.escape)
        stop(timerfindall);
        delete(timerfindall);
        close all
      end
    end
    function QuitFcn(~,src,~)
      delete(src);
    end
  end
end
