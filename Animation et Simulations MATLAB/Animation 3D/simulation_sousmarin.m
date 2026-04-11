function h = ocean_simulatoor(~)
% function h = ocean_simulator(~)
%
% Mini gui to experiment a few parameters used to create a wave simulation
% v1 - 2015/06/02 - Hoki 
% MIT licence

%% // Default parameters
param.meshsize  = 128 ;     %// main grid size
param.patchsize = 200 ;     
param.windSpeed = 100  ;    %// what unit ? [m/s] ??
param.winddir   = 90   ;    %// Azimuth
param.rng = 13 ;            %// setting seed for random numbers
param.A         = 75 ;    %// Scaling factor
param.g         = 9.81 ;    %// gravitational constant

param.xLim = [-10 10] ;     %// domain limits X
param.yLim = [-10 10] ;     %// domain limits Y
param.zLim = [-10 10] ;

%% // Pre-set modes
presetModes.names     = {'Calm','Windy lake','Swell','T-Storm','Tsunami','Custom'} ;
presetModes.winddir   = [  90   ,    90   ,   220,     90     ,   90   ] ;
presetModes.patchsize = [  150  ,   500 ,    180   ,     128     ,   128   ] ;
presetModes.meshsize  = [  128  ,   480 ,    215   ,     128     ,   128   ] ;

%% // start first instance
if nargin == 1
    h  = init_gui(param,presetModes,true) ;	%// Create a new instance
else
    h  = init_gui(param,presetModes) ;	%// Delete all instances then redraw a new one
end
init_surf(h,param) ;                %// update the surface with default parameters

%% // save parameters into application data
setappdata(h.fig,'param',param) ; 
setappdata(h.fig,'presetModes',presetModes) ;

end

function [H0, W, Grid_Sign] =  initialize_wave( param )
    rng(param.rng);  %// setting seed for random numbers

    gridSize = param.meshsize * [1 1] ;

    meshLim = pi * param.meshsize / param.patchsize ;
    N = linspace(-meshLim , meshLim , param.meshsize ) ;
    M = linspace(-meshLim , meshLim , param.meshsize ) ;
    [Kx,Ky] = meshgrid(N,M) ;

    K = sqrt(Kx.^2 + Ky.^2);    %// ||K||
    W = sqrt(K .* param.g);     %// deep water frequencies (empirical parameter)

    [windx , windy] = pol2cart( deg2rad(param.winddir) , 1) ;

    P = phillips(Kx, Ky, [windx , windy], param.windSpeed, param.A, param.g) ;
    H0 = 1/sqrt(2) .* (randn(gridSize) + 1i .* randn(gridSize)) .* sqrt(P); % height field at time t = 0

    if nargout == 3
        Grid_Sign = signGrid( param.meshsize ) ;
    end
end

function Z = calc_wave( H0,W,time,Grid_Sign )
    % recalculate the grid sign if not supplied in input
    if nargin < 4
        param = getappdata(gcf, 'param');
        Grid_Sign = signGrid( param.meshsize ) ;
    end
    % Assign time=0 if not specified in input
    if nargin < 3 ; time = 0 ; end
    
    wt = exp(1i .* W .* time ) ;
    Ht = H0 .* wt + conj(rot90(H0,2)) .* conj(wt) ;  
    Z = real( ifft2(Ht) .* Grid_Sign ) ;
end
    
function P = phillips(Kx, Ky, windDir, windSpeed, A, g)
    K_sq = Kx.^2 + Ky.^2;
    L = windSpeed.^2 ./ g;
    k_norm = sqrt(K_sq) ;
    WK = Kx./k_norm * windDir(1) + Ky./k_norm * windDir(2);
    P = A ./ K_sq.^2 .* exp(-1.0 ./ (K_sq * L^2)) .* WK.^2 ;
    P( K_sq==0 | WK<0 ) = 0 ;
end

function sgn = signGrid(n)
    [x,y] = meshgrid(1:n,1:n) ;
    sgn = ones( n ) ;
    sgn(mod(x+y,2)==0) = -1 ;
end

function init_surf(h,param)
%// Define the grid X-Y space
x = linspace( param.xLim(1) , param.xLim(2) , param.meshsize ) ;
y = linspace( param.yLim(1) , param.yLim(2) , param.meshsize ) ;
[X,Y] = meshgrid(x, y);

%// initialise wave coefficients   
[H0, W, Grid_Sign] =  initialize_wave( param ) ;

%// calculate wave at t0
t0 = 0 ;
Z = calc_wave( H0 , W , t0 , Grid_Sign ) ;

%// Display the initial wave surface
set( h.surf , 'XData',X , 'YData',Y , 'ZData',Z )
set( h.ax   , 'XLim',param.xLim , 'YLim',param.yLim , 'ZLim',param.zLim )

%// Save coeffs for futur use
setappdata( h.fig , 'H0' , H0 )
setappdata( h.fig , 'W'  , W )
setappdata( h.fig , 'Grid_Sign'  , Grid_Sign )
setappdata( h.fig , 'param' , param) ;

nom_fichier = '12219_boat_v2_L2.obj';
    
    % Vérification du fichier
    if isfile(nom_fichier)
        obj = lire_obj_local(nom_fichier); 
        V = obj.v; F = obj.f;
        L = 15;
        min_V = min(V); max_V = max(V);
        centre = (min_V + max_V) / 2;
        V = V - centre; 
        longueur_actuelle = max(V(:,1)) - min(V(:,1));
        facteur = L / longueur_actuelle;
        V = V * facteur; 
    
        X_nav = V(:,1); 
        Y_nav = V(:,2);
        Z_nav = V(:,3);
        Decalage_Z = 4; 
        V(:,3) = V(:,3) + Decalage_Z;
        setappdata(h.fig, 'boat_V_base', V);
        hold(h.ax, 'on');
        if isfield(h, 'boat') && ishandle(h.boat)
            delete(h.boat); % Supprime l'ancien bateau
        end
        h.boat = patch(h.ax, 'Faces', F, 'Vertices', V, 'FaceColor', [0.7 0.7 0.7], 'EdgeColor', 'none', 'SpecularStrength', 0.2);

        % INITIALISATION EXPLOSION
        % Couleurs du bateau
        set(h.boat, 'FaceVertexCData', repmat([0.7 0.7 0.7], size(V,1), 1), 'FaceColor', 'interp');
        
        % Création de la sphère d'explosion
        [sx, sy, sz] = sphere(20);
        h.sphere_x = sx; h.sphere_y = sy; h.sphere_z = sz;
        h.explosion_sphere = surf(h.ax, sx, sy, sz, 'FaceColor', 'red', 'FaceAlpha', 0.2, 'EdgeColor', 'none', 'Visible', 'off');
        
        % Variables d'état stockées
        setappdata(h.fig, 'explosion_active', false);
        setappdata(h.fig, 'explosion_t', 0);
        setappdata(h.fig, 'explosion_pos', [0, 0, -5]); % Position sous le bateau

        hold(h.ax, 'off');
        guidata(h.fig, h);
    else
        disp("Fichier obj introuvable")
    end

%// Reset the wave animation parameters
animate_wave(h,true) ;

%// Display side patch if option checked
displaySidePatch = get(h.chkSidePatch,'Value') ; %// get checkbox state
init_SidePatch(h.fig,displaySidePatch) ; %// draw or erase side patches

end

function init_SidePatch(hobj,displaySidePatch)
    h = guidata( hobj ) ;
    param = getappdata( h.fig , 'param' ) ;

    if ~isfield( h , 'pt' ) ; h.pt = -1 ; end

    if displaySidePatch
        if any(~ishandle(h.pt))
            delete(h.pt(ishandle(h.pt)))
            x = linspace( param.xLim(1) , param.xLim(2) , param.meshsize ) ;
            y = linspace( param.yLim(1) , param.yLim(2) , param.meshsize ) ;
            pcol = [0.2857,1,0.7143] ;

            xface = [ x param.xLim(2) param.xLim(1) ] ;
            yface = [ y param.yLim(2) param.yLim(1) ] ;
            face0 = zeros(size(xface)) ;
            faceZ = [zeros(size(x)) param.zLim(1) param.zLim(1)] ;

            h.pt(1) = handle( patch( xface , face0+param.yLim(1) , faceZ ,pcol ) ) ;
            h.pt(3) = handle( patch( xface , face0+param.yLim(2) , faceZ ,pcol ) ) ;
            h.pt(2) = handle( patch( face0+param.xLim(1) , yface , faceZ ,pcol ) ) ;
            h.pt(4) = handle( patch( face0+param.xLim(2) , yface , faceZ ,pcol ) ) ;

            h.pt = handle(h.pt) ;
            set(h.pt, 'Facecolor',pcol , 'FaceAlpha',0.5 , 'EdgeColor','none')

            guidata( h.fig , h )
        end
        
        Z = get( h.surf,'ZData') ;
        h.pt(1).ZData(1:end-2) = Z(1,:) ;
        h.pt(2).ZData(1:end-2) = Z(:,1) ;
        h.pt(3).ZData(1:end-2) = Z(end,:) ;
        h.pt(4).ZData(1:end-2) = Z(:,end) ;

    else 
        delete(h.pt(ishandle(h.pt)))
    end
end

function recalc_surf(hobj,~)
    h = guidata(hobj) ;
    param = getappdata(h.fig,'param') ;
    param = update_options( h , param ) ; 
    init_surf( h , param)
end

function animate_wave(h,~)
    persistent time H0 W Grid_Sign hs
    
    if nargin == 2
        time = 0 ;
        H0 = getappdata( h.fig , 'H0' ) ;
        W  = getappdata( h.fig , 'W'  ) ;
        Grid_Sign = getappdata( h.fig , 'Grid_Sign' ) ;      
        hs = handle( h.surf ) ;
        return
    end
    time = time + 0.1 ;
    
    %// update wave surface
    Z = calc_wave( H0,W,time,Grid_Sign ) ;
    hs.ZData = Z ;
    
    %// update side patches
    isPatchDisplayed = logical( get(h.chkSidePatch,'Value') ) ;
    if isPatchDisplayed
            if ishandle(h.pt(1)) ;  h.pt(1).ZData(1:end-2) = Z(1,:)   ;  end
            if ishandle(h.pt(2)) ;  h.pt(2).ZData(1:end-2) = Z(:,1)   ;  end
            if ishandle(h.pt(3)) ;  h.pt(3).ZData(1:end-2) = Z(end,:) ;  end
            if ishandle(h.pt(4)) ;  h.pt(4).ZData(1:end-2) = Z(:,end) ;  end
    end

    % ANIMATION DE L'EXPLOSION
    explosion_active = getappdata(h.fig, 'explosion_active');
    if ~isempty(explosion_active) && explosion_active
        exp_t = getappdata(h.fig, 'explosion_t');
        exp_t = exp_t + 0.1; % Avancement du temps
        setappdata(h.fig, 'explosion_t', exp_t);
        exp_pos = getappdata(h.fig, 'explosion_pos');
        V_base = getappdata(h.fig, 'boat_V_base');
        
        if isfield(h, 'boat') && ishandle(h.boat) && ~isempty(V_base)
            % Distance de CHAQUE SOMMET à l'explosion (N x 1)
            Dist = sqrt((V_base(:,1) - exp_pos(1)).^2 + (V_base(:,2) - exp_pos(2)).^2 + (V_base(:,3) - exp_pos(3)).^2);
            
            % Paramètres de l'onde
            Vitesse_Onde = 8;        % [m/s]
            Epaisseur_Totale = 6;    % [m] Largeur de la zone colorée
            R_onde_centre = Vitesse_Onde * exp_t; % Position du front d'onde

            % Les couleurs de l'effet
            COULEUR_BASE = [0.7 0.7 0.7]; % Gris (pas d'impact)
            C1_BLEU = [0 0.4 1];          % Bleu (faible impact)
            C2_JAUNE = [1 1 0];      % Jaune (moyen impact)
            C3_ROUGE = [1 0.1 0];         % Rouge (fort impact) 

            % Impact relatif
            % Dist_Relativ > 0: Derrière le front d'onde
            % Dist_Relativ < 0: Devant le front d'onde
            Dist_Relativ = (R_onde_centre - Dist) / Epaisseur_Totale;

            % Matrice de couleurs (N_sommets x 3)
            Couleurs_RGB = repmat(COULEUR_BASE, size(V_base,1), 1);
            
            % Le Gradient
            % Points touchés (Dist_Relativ > 0)
            Est_Touche = (Dist_Relativ > 0);
            
            % Les points juste derrière le front d'onde sont BLEUS
            Is_Bleu = Est_Touche & (Dist_Relativ < 1/3);
            % Les points au milieu sont JAUNES
            Is_Vert = Est_Touche & (Dist_Relativ >= 1/3) & (Dist_Relativ < 2/3);
            % Les points proches du centre sont ROUGES
            Is_Rouge = Est_Touche & (Dist_Relativ >= 2/3);

            % Appliquer les couleurs
            Couleurs_RGB(Is_Bleu, :) = repmat(C1_BLEU, sum(Is_Bleu), 1);
            Couleurs_RGB(Is_Vert, :) = repmat(C2_JAUNE, sum(Is_Vert), 1);
            Couleurs_RGB(Is_Rouge, :) = repmat(C3_ROUGE, sum(Is_Rouge), 1);

           % Animation des couleurs (lisser et interpolation)
            for i = 1:size(V_base,1)
                d = Dist_Relativ(i);
                if d < 0
                    
                elseif d < 1/3 % Zone Bleu
                    frac = d / (1/3);
                    Couleurs_RGB(i,:) = COULEUR_BASE * (1-frac) + C1_BLEU * frac;
                elseif d < 2/3 % Zone Jaune
                    frac = (d - 1/3) / (1/3);
                    Couleurs_RGB(i,:) = C1_BLEU * (1-frac) + C2_JAUNE * frac;
                elseif d < 1 % Zone Rouge
                    frac = (d - 2/3) / (1/3);
                    Couleurs_RGB(i,:) = C2_JAUNE * (1-frac) + C3_ROUGE * frac;
                else
                     Couleurs_RGB(i,:) = C3_ROUGE;
                end
            end
            

            % Mettre à jour la couleur du bateau
            set(h.boat, 'FaceVertexCData', Couleurs_RGB, 'FaceColor', 'interp');
           
        end
        
        % Mise à jour de la sphère d'explosion 
        if isfield(h, 'explosion_sphere') && ishandle(h.explosion_sphere)
            set(h.explosion_sphere, 'XData', h.sphere_x * R_onde_centre + exp_pos(1), ...
                                    'YData', h.sphere_y * R_onde_centre + exp_pos(2), ...
                                    'ZData', h.sphere_z * R_onde_centre + exp_pos(3), ...
                                    'Visible', 'on');
        end
        
        % FIN
        if exp_t > 2.0
            setappdata(h.fig, 'explosion_active', false);
            if isfield(h, 'boat') && ishandle(h.boat)
                set(h.boat, 'FaceVertexCData', repmat([0.7 0.7 0.7], size(V_base,1), 1)); 
            end
            set(h.explosion_sphere, 'Visible', 'off'); 
        end
    end
end

function param = update_options( h , param )
    param.meshsize  = round( get( h.sldMeshSize ,'Value' ) ) ;
    param.patchsize = round( get( h.sldPatchSize,'Value' ) ) ;
    param.winddir = get( h.sldWindDir,'Value' )  ;
    
    set( h.lblMeshSize  , 'String', sprintf('Mesh size = %d'  ,param.meshsize )  ) ;
    set( h.lblPatchSize , 'String', sprintf('Patch size = %d' ,param.patchsize ) ) ;
    set( h.lblWindDir   , 'String', sprintf('Wind Dir = %g'   ,param.winddir )   ) ;
end

function h = init_gui(param,presetModes,~)

pnlH    = 0.2 ;  
marginH = 0.1 ;  
marginW = 0.05 ; 
lineH   = 0.10 ; 
lblW    = 0.2  ; 
btnW    = 0.10 ; % Ajustée

if nargin < 3
    hFigOld = findobj('Type','Figure','Tag','OceanSim') ;
    close(hFigOld)
end

h.fig   = figure('Name','Ocean simulator','Tag','OceanSim','CloseRequestFcn',@CloseGUI) ;
movegui(h.fig,'center') 

h.timer = timer('Period',0.1,'TimerFcn',{@timerCallback,h.fig},'TasksToExecute',Inf ,'ExecutionMode','fixedRate') ;

h.pnlsettings = uipanel('Position',[0   0   1 pnlH   ]) ; 
h.pnldisplay  = uipanel('Position',[0 pnlH  1 1-pnlH ]) ; 

btnOptions = { 'Parent',h.pnlsettings , 'Style','pushbutton' , 'Unit','Normalized'  } ;
chkOptions = { 'Parent',h.pnlsettings , 'Style','checkbox'   , 'Unit','Normalized'  } ;
cmbOptions = { 'Parent',h.pnlsettings , 'Style','popupmenu'  , 'Unit','Normalized'  } ;
edtOptions = { 'Parent',h.pnlsettings , 'Style','edit'       , 'Unit','Normalized'  } ;
lblOptions = { 'Parent',h.pnlsettings , 'Style','text'       , 'Unit','Normalized' , 'String','' } ;
sldOptions = { 'Parent',h.pnlsettings , 'Style','Slider'     , 'Unit','Normalized' , 'Callback',@recalc_surf } ;

getLblPos = @(ipos) [marginW        (ipos+1)*marginH+(ipos-1)*lineH lblW               lineH ] ;
getSldPos = @(ipos) [2*marginW+lblW (ipos+1)*marginH+(ipos-1)*lineH 1-(3*marginW+lblW) lineH ] ;
getBtnPos = @(ipos,jpos) [jpos*marginW+(jpos-1)*btnW (ipos+1)*marginH+(ipos-1)*lineH btnW lineH ] ;

ipos = 0 ; jpos = 0 ;

ipos = ipos+1 ;
h.lblMeshSize  = uicontrol( lblOptions{:} , 'Position',getLblPos(ipos) ) ;
h.sldMeshSize  = uicontrol( sldOptions{:} , 'Position',getSldPos(ipos) , 'Min',32 , 'Max',512 , 'Value',param.meshsize ) ;

ipos = ipos+1 ;
h.lblPatchSize = uicontrol( lblOptions{:} , 'Position',getLblPos(ipos) ) ;
h.sldPatchSize = uicontrol( sldOptions{:} , 'Position',getSldPos(ipos) , 'Min',50 , 'Max',500 , 'Value',param.patchsize  ) ;

ipos = ipos+1 ;
h.lblWindDir  = uicontrol( lblOptions{:} , 'Position',getLblPos(ipos) ) ;
h.sldWindDir  = uicontrol( sldOptions{:} , 'Position',getSldPos(ipos) , 'Min',0 , 'Max',359 , 'Value',param.winddir , 'SliderStep',[1 10]/359 ) ;

% def
ipos = ipos+1 ;
jpos = jpos+1 ; h.cmbPreset    = uicontrol( cmbOptions{:} , 'Position',getBtnPos(ipos,jpos) , 'String',presetModes.names , 'Value',1, 'Callback',@choose_preset ) ;
jpos = jpos+1 ; h.chkSidePatch = uicontrol( chkOptions{:} , 'Position',getBtnPos(ipos,jpos) , 'String','Side patch' , 'Value',0, 'Callback',@toggle_side_patch ) ;
jpos = jpos+1 ; h.btnAnimate   = uicontrol( btnOptions{:} , 'Position',getBtnPos(ipos,jpos) , 'String','Animate' , 'Callback',@toggle_animation ) ;

% Nouveau  bouton
jpos = jpos+1 ; h.btnExplosion = uicontrol( btnOptions{:} , 'Position',getBtnPos(ipos,jpos) , 'String','Onde de choc' , 'Callback',@trigger_explosion ) ;


%jpos = jpos+1 ; h.btnMakeGIF   = uicontrol( btnOptions{:} , 'Position',getBtnPos(ipos,jpos) , 'String','Make GIF' , 'Callback',@makeGIF ) ;
%jpos = jpos+1 ; h.edtGIFname   = uicontrol( edtOptions{:} , 'Position',getBtnPos(ipos,jpos) , 'String','DancingWave.gif' ) ;

h.ax   = axes('Parent',h.pnldisplay) ;  
h.surf = surf( NaN(2) ) ;               
h.pt = -1 ;                             

h.ax   = handle( h.ax ) ;
h.surf = handle( h.surf ) ; 

h.ax.Position = get( h.pnldisplay,'Position') ;
axis(h.ax, 'equal');  
axis(h.ax, 'vis3d');  
axis(h.ax, 'off');    
shading interp                          

camzoom(h.ax, 1.5); 

blue = linspace(0.4, 1.0, 25).' ; cmap = [blue*0, blue*0, blue];
colormap(cmap)
h.light_handle = lightangle(-45,30) ;   

set(h.surf,'FaceLighting','phong',...
    'AmbientStrength',.3,'DiffuseStrength',.8,...
    'SpecularStrength',.9,'SpecularExponent',25,...
    'BackFaceLighting','unlit')

guidata( h.fig , h ) 

end

function toggle_side_patch(hobj,~)
    displaySidePatch = get(hobj,'Value') ; 
    init_SidePatch(hobj,displaySidePatch) ; 
end

function toggle_animation(hobj,~)
    h = guidata( hobj ) ;
    btnStr = get(h.btnAnimate,'String') ; 
    if strcmp('Animate',btnStr)
        set( h.btnAnimate,'String','Stop' )
        start(h.timer) ;
    else
        set( h.btnAnimate,'String','Animate' )
        stop(h.timer) ;
    end
end

function choose_preset(hobj,~)
    h = guidata( hobj ) ;
    presetModes = getappdata(h.fig,'presetModes') ;

    psetIndex = round( get(h.cmbPreset,'Value') ) ;
    set(h.sldWindDir   ,'Value' , presetModes.winddir(psetIndex)) 
    set(h.sldPatchSize ,'Value' , presetModes.patchsize(psetIndex))
    set(h.sldMeshSize  ,'Value' , presetModes.meshsize(psetIndex))
    recalc_surf(h.fig) ;
end

function timerCallback(~,~,hfig)
    h = guidata( hfig ) ;
    animate_wave(h) ;
end

function CloseGUI(hfig,~)
    h = guidata(hfig) ;
    try delete(h.timer) ; catch ; disp('Timer could not be deleted') ; end
    delete(h.fig) 
end

function makeGIF(hobj,~)
    h = guidata( hobj ) ;
    gifname = get( h.edtGIFname,'String') ;
    if ~strcmpi( gifname(end-3:end) , '.gif' )
        gifname = [gifname '.gif'] ;
    end
    
    nFrame = 50 ;
    hframe = h.ax ;
    hsurf  = h.surf ;
    
    H0 = getappdata( h.fig , 'H0' ) ;
    W  = getappdata( h.fig , 'W'  ) ;
    Grid_Sign = getappdata( h.fig , 'Grid_Sign' ) ;      

    f = getframe(hframe) ;
    [im,map] = rgb2ind(f.cdata,256,'nodither');
    im(1,1,1,nFrame) = 0;
    iframe = 0 ;
    
    isPatchDisplayed = logical( get(h.chkSidePatch,'Value') ) ;
    if isPatchDisplayed
        alphapt = get( h.pt(ishandle(h.pt) ) , 'FaceAlpha') ;   
        alphapt = alphapt{1} ;
        set( h.pt(ishandle(h.pt) ) , 'FaceAlpha',1 )            
    end
    
    for time = (0:nFrame-1)*.5
        Z = calc_wave( H0,W,time,Grid_Sign ) ;
        hsurf.ZData = Z ;

        if isfield( h , 'pt' )
            if ishandle(h.pt(1)) ;  h.pt(1).ZData(1:end-2) = Z(1,:)   ;  end
            if ishandle(h.pt(1)) ;  h.pt(2).ZData(1:end-2) = Z(:,1)   ;  end
            if ishandle(h.pt(1)) ;  h.pt(3).ZData(1:end-2) = Z(end,:) ;  end
            if ishandle(h.pt(1)) ;  h.pt(4).ZData(1:end-2) = Z(:,end) ;  end
        end
        pause(0.001);

        f = getframe(hframe) ;
        iframe= iframe+1 ;
        im(:,:,1,iframe) = rgb2ind(f.cdata,map,'nodither');
    end
    imwrite(im,map,gifname,'DelayTime',0,'LoopCount',inf) 
    disp([num2str(nFrame) ' frames written in file: ' gifname])
    
    if isPatchDisplayed  
        set( h.pt(ishandle(h.pt) ) , 'FaceAlpha',alphapt )            
    end
end

% Lire un fichier OBJ 
function obj = lire_obj_local(fname)
    v = []; f = [];
    fid = fopen(fname);
    while 1
        tline = fgetl(fid);
        if ~ischar(tline), break, end
        ln = sscanf(tline,'%s',1);
        if strcmp(ln, 'v') 
            v = [v; sscanf(tline(2:end),'%f')'];
        elseif strcmp(ln, 'f') 
            str = tline(2:end);
            str = regexprep(str, '/[0-9]*', ''); 
            face_idx = sscanf(str, '%f')';
            if length(face_idx) == 3
                f = [f; face_idx];
            elseif length(face_idx) == 4 
                f = [f; face_idx([1 2 3]); face_idx([1 3 4])];
            end
        end
    end
    fclose(fid);
    obj.v = v; obj.f = f;
end

% Bouton explosion
function trigger_explosion(hobj, ~)
    h = guidata(hobj);
    setappdata(h.fig, 'explosion_active', true);
    setappdata(h.fig, 'explosion_t', 0);
end

