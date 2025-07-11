% Declares a Bezierauto to return x, y, w
function [x y w] = Bezierauto(Px,Py,W,n)
% =============================================================
%%% Input
% Px: [P0x;P1x;P2x;...], x coordinate of control point
% Py: [P0y;P1y;P2y;...], y coordinate of control point
% W : [P0w;P1w;P2w;...], radius of control circle
% n: segment number
%%% Output
% x = [x(1);x(2);x(3);...;x(n+1)], x coordinate of Bezier curve
% y = [y(1);y(2);y(3);...;y(n+1)], y coordinate of Bezier curve
% w : [w(1);w(2);w(3);...], diameter of variable circles
% =============================================================
% Parameter Values
T = 0:1/n:1;
% Determine number of control points
a = size(Px,1);
% Binomial Coefficients for Bernstein Polynomials
Pas = pascal(a-1);                      
C = zeros(1,a);  
Bez = zeros(n+1,a);
C(1) = 1;  
C(a) = 1;
% Fill in Binomial Coefficient
for i = 2:a-1
    C(i) = Pas(a-(i-1),i);
end
% Compute Bernstein Basis for All t-values
for i = 1:n+1
    t = T(i);
    % First Bez index
    Bez(i,1) = C(1)*(1-t)^(a-1);
    for j = 2:a-1
        % Middle Bez indexs
        Bez(i,j) = C(j)*(1-t)^(a-j)*(t)^(j-1);
    end
    % Last Bez index
    Bez(i,a) = C(a)*(t)^(a-1);
end
% Multiply Basis with Control Points
x = Bez*Px;
y = Bez*Py;
w = Bez*W;