classdef particle < handle
    
    properties
        x
        y
        z
        vx
        vy
        vz
        Z
        amu
        hitWall
    end
    
    methods

        function [T Y] = move (p, end_t, dt, E, B, xyz)
            
            
            status = 0;
            
            IC = [p.x p.y p.z p.vx p.vy p.vz]';
            tSpan = [0,end_t];
            
            options = odeset('InitialStep',dt,'MaxStep',dt);
                        
            [T Y] = ode45(@(t,y) myode(t,y,p,E,B,xyz),tSpan,IC);%,options);
            
            p.x = Y(end,1); % this doesn't seem to work, i.e., cannot modify p outside this scope :(
            p.y = Y(end,2);
            p.z = Y(end,3);
            
            p.vx = Y(end,4);
            p.vy = Y(end,5);
            p.vz = Y(end,6);
      
        end



        function  boris(part,B_local,E_local,dt)
            constants
            
            B = B_local;
            E = E_local;
            BMagPart =norm(B);
            
            %%Constants used in Boris method Lorentz Integrator
            q_prime = part.Z*Q/(part.amu*MI)*dt/2;
            coeff = 2*q_prime/(1+(q_prime*BMagPart).^2);
            
            %Boris Method Lorentz Integrator
            v = [part.vx part.vy part.vz];
            r = [part.x part.y part.z];
            
            v_minus = v + q_prime*E;
            
            v = v_minus + q_prime*cross(v_minus,B);
            
            v = v_minus + coeff*cross(v,B);
            
            v = v + q_prime*E;
            
            r = r + v*dt;

            part.x =r(1);
            part.y =r(2);
            part.z =r(3);
            part.vx = v(1);
            part.vy = v(2);
            part.vz = v(3);
        end
        
        function [T Yr] = rk4(part,xV,yV,zV,Bx,By,Bz,BMag,Ex,Ey,Ez,end_t,dt,steps)
            constants

            m = MI*part.amu;
            q_m = part.Z*Q/m;
            E = [0 0 0];
            B = [0 0 0];
    
            v = [part.vx part.vy part.vz];
            r = [part.x part.y part.z];
            
            h = end_t/steps;
            T = zeros(steps+1,1);
            Yr = zeros(steps+1,3);
            Yv = zeros(steps+1,3);
            T(1) = 0;
            Yr(1,:) = r;
            Yv(1,:) = v;
                for j=1:steps
                    tj = T(j);
                    yjr = Yr(j,:);
                    yjv = Yv(j,:);
                    [E B] = field_interp(yjr,xV,yV,zV,Bx,By,Bz,Ex,Ey,Ez);
                    k1r = h*yjv;
                    k1v = h*q_m*(E + cross(yjv,B));
                    
                    [E B] = field_interp(yjr+k1r/2,xV,yV,zV,Bx,By,Bz,Ex,Ey,Ez);
                    k2r = h*(yjv+ k1v/2);
                    k2v = h*q_m*(E + cross((yjv+ k1v/2),B));
                    
                    
                    [E B] = field_interp(yjr+k2r/2,xV,yV,zV,Bx,By,Bz,Ex,Ey,Ez);
                    k3r = h*(yjv+ k2v/2);
                    k3v = h*q_m*(E + cross((yjv+ k2v/2),B));
                    
                    [E B] = field_interp(yjr+k3r,xV,yV,zV,Bx,By,Bz,Ex,Ey,Ez);
                    k4r = h*(yjv+ k3v);
                    k4v = h*q_m*(E + cross((yjv+ k3v),B));
                    
                    Yr(j+1,:) = yjr + (k1r + 2*k2r + 2*k3r + k4r)/6;
                    Yv(j+1,:) = yjv + (k1v + 2*k2v + 2*k3v + k4v)/6;
                    T(j+1) = h*j;
                          
                end
                
            function [E B] = field_interp(r,xV,yV,zV,Bx,By,Bz,Ex,Ey,Ez)
                B(1) = interpn(xV,yV,zV,Bx,r(1),r(2),r(3));
                B(2) = interpn(xV,yV,zV,By,r(1),r(2),r(3));
                B(3) = interpn(xV,yV,zV,Bz,r(1),r(2),r(3));
                
                
                E(1) = interpn(xV,yV,zV,Ex,r(1),r(2),r(3));
                E(2) = interpn(xV,yV,zV,Ey,r(1),r(2),r(3));
                E(3) = interpn(xV,yV,zV,Ez,r(1),r(2),r(3));
            end
        
        end
        function  ionization(p,dt,T_local,n_local,RateCoeff,T_b,dens_b,State,r1)
            max_state = max(State(:));
            if p.Z < max_state
            constants
            
            
            minT = min(T_b(:));
            T=T_local(1);
            if log10(T) > minT
                n=n_local(1);
                Coeff = interpn(dens_b,T_b,RateCoeff(:,:,p.Z+1),log10(n/1e6),log10(T));
                
                if ( isnan(Coeff) )
                    error('Ionization interpolation out of range')
                end
                
                tion = 1/(10^Coeff*n/1E6);
                P1 = 1-exp(-dt/tion);
                
               
                if r1 <= P1
                    p.Z = p.Z+1;
                end
            end
            end
        end
        
        function recombination(p,dt,T_local,n_local,RecombCoeff,T_b,dens_b,State,r2)
            
            constants
            
            minT = min(T_b);
            minN = min(dens_b);
            T=T_local(1);
            n=n_local(1);
            T = log10(T);
            n = log10(n/1e6);
            if (T > minT) && (n > minN) && p.Z >0

                Coeff = interpn(dens_b,T_b,RecombCoeff(:,:,p.Z),n,T);
                
                tion = 1/(10^Coeff*10^n);
                P1 = 1-exp(-dt/tion);
                
                
                if r2 <= P1
                    p.Z = p.Z-1;
                end
            end
        end
        
        function [nu_s, nu_d, nu_par, nu_E] = slow(part,T_local,n_local,nS,amu,Z)

            constants
            persistent v_norm_persistent;
            
            v = [part.vx part.vy part.vz];
            
            flow_v = [0 0 0]; %This will need to be calculated or interpolated in the future
            v_relative = v - flow_v;
            v_norm = norm(v_relative);
            if v_norm == 0
                v_norm = v_norm_persistent;
            else
                v_norm_persistent = v_norm;
            end
            nu_s = 0;
            nu_d = 0;
            nu_par = 0;
            nu_E = 0;
            
            z = part.Z;
            m = part.amu*MI;
            for j=1:nS
                
                zbackground = Z(j);
                
                mbackground = amu(j)*MI;
                T = T_local(j);
                n = n_local(j);
                
                lam_d = sqrt(EPS0*T/(n*zbackground^2*Q));%only one q in order to convert to J
                lam = 4*pi*n*lam_d^3;
                gam = Q^4*z^2*zbackground^2*log(lam)/(m*m*4*pi*EPS0*EPS0);

                a = mbackground/(2*T*Q); %q is just to convert units - no z needed
                
                x = v_norm^2*a;
                psi_prime = 2*sqrt(x/pi)*exp(-x);
                psi_psiprime = erf(sqrt(x));
                psi = psi_psiprime - psi_prime;
                nu_0 = gam*n/v_norm^3;
                nu_s =nu_s -(1+m/mbackground)*psi*nu_0;
                nu_d = nu_d + 2*(psi_psiprime - psi/(2*x))*nu_0;
                nu_par = nu_par + psi/x*nu_0;
                nu_E = nu_E+2*(m/mbackground*psi - psi_prime)*nu_0;


            end
          


            end
                   function [e1 e2 e3] = direction(p,B_local,E_local)
                       
                        
                       persistent f1;
                       persistent f2;
                       persistent f3;
                        
                       v = [p.vx p.vy p.vz];

                       

                       B_unit = B_local/norm(B_local);
                       
                       flow_v = [0 0 0]; %This will need to be calculated or interpolated in the future
                       v_relative = v - flow_v;
                       
                       g = v_relative;
                       e3 = g/norm(g);
                       
                       s1 = dot(e3,B_unit);
                       s2 = sqrt(1-s1^2);
                       
                       e1 = 1/s2*(s1*e3 - B_unit);
                       e2 = -1/s2*cross(e3,B_unit);

                        %vector_plot
                       if any([isnan(e1) isnan(e2) isnan(e3)]) == 0
                           f1 = e1;
                           f2 = e2;
                           f3 = e3;
                       else
                           e1 = f1;
                           e2 = f2;
                           e3 = f3;
                       end
                      
                   end
            
                   function cfDiffusion(p,B_local,xyz,Dperp,dt,s3)
                       persistent Dperp_pers;
                       B_unit = B_local/norm(B_local);
                       %%%%%%%%%%Calculation of direction perpendicular to B
                       
                       phi_rnd = 2*pi*s3;
                       eperp(1) = cos(phi_rnd);
                       eperp(2) = sin(phi_rnd);
                       eperp(3) = (-eperp(1)*B_unit(1) - eperp(2)*B_unit(2))/B_unit(3);
                       norme = norm([eperp(1) eperp(2) eperp(3)]);
                       eperp(1) = eperp(1)/norme;
                       eperp(2) = eperp(2)/norme;
                       eperp(3) = eperp(3)/norme;
                       
                       D_local = interpn(xyz.x,xyz.y,xyz.z,Dperp,p.x,p.y,p.z);
                       if isnan(D_local) ==1
                           D_local = 0;
                       else
                           Dperp_pers = D_local;
                       end
                       
                       if p.hitWall == 1
                           D_local = 0;
                       end
                       
                       if p.Z == 0
                           D_local = 0;
                       end
                       
                       p.x = p.x + sqrt(6*D_local*dt)*eperp(1);
                       p.y = p.y + sqrt(6*D_local*dt)*eperp(2);
                       p.z = p.z + sqrt(6*D_local*dt)*eperp(3);
                       
                       
                   end
                   
                   function diagnostics = dv_coll(p, e1,e2,e3,nu_s,nu_d,nu_par,nu_E,dt,random)
                       constants
                       
                       v_norm = norm([p.vx p.vy p.vz]);
                       T = v_norm^2*p.amu*MI*pi/8/Q;

                       dv_slow =  e1*(nu_s*dt);
                       norm_slow = norm(v_norm*dv_slow);
                       
                       plus_minus1 = round(random(1))*2-1;
                       dv_par = e1*plus_minus1*sqrt(nu_par*dt);
                       dv_parallel = dv_slow+ dv_par;
                       norm_par = norm(v_norm*dv_par);
                       norm_parallel = norm(v_norm*dv_parallel);


                       plus_minus2 = round(random(2))*2-1;
                       dv_perp1 =  e1*plus_minus2*sqrt(nu_d/2*dt);
                       norm_perp1 = plus_minus2*norm(v_norm*dv_perp1);
                       plus_minus3 = round(random(3))*2-1;
                       dv_perp2 =  e2*plus_minus3*sqrt(nu_d/2*dt);
                       norm_perp2 = plus_minus3*norm(v_norm*dv_perp2);

                     
                       ez = (1+nu_s*dt+ plus_minus1*sqrt(nu_par*dt) );%
                       v_collisions = v_norm*(1-nu_E/2*dt)*(e3*ez + dv_perp1 + dv_perp2); %+ dv_perp1 + dv_perp2
                       p.vx = v_collisions(1);
                       p.vy = v_collisions(2);
                       p.vz = v_collisions(3);
                       
                       dv_collisions = v_collisions - v_norm;
                       
                       diagnostics = [T dv_collisions norm_slow norm_par norm_parallel norm_perp1 norm_perp2];
                   end
                   
             function [E_local, B_local] = field_interp(p,xyz,Bfield,Efield)
                 persistent E;
                 persistent B;
                 
                 
                 
                 B_local(1) = interpn(xyz.x,xyz.y,xyz.z,Bfield.x,p.x,p.y,p.z);
                 B_local(2) = interpn(xyz.x,xyz.y,xyz.z,Bfield.y,p.x,p.y,p.z);
                 B_local(3) = interpn(xyz.x,xyz.y,xyz.z,Bfield.z,p.x,p.y,p.z);
                 
                 
                 E_local(1) = interpn(xyz.x,xyz.y,xyz.z,Efield.x,p.x,p.y,p.z);
                 E_local(2) = interpn(xyz.x,xyz.y,xyz.z,Efield.y,p.x,p.y,p.z);
                 E_local(3) = interpn(xyz.x,xyz.y,xyz.z,Efield.z,p.x,p.y,p.z);
                 
                 if any([isnan(E_local) isnan(B_local)]) == 0
                     E=E_local;
                      B=B_local;
                 else
                     E_local = E;
                     B_local = B;
                 end
             end
            function [T_local, n_local] = Tn_interp(part,xyz,temp_eV,density,nS)
                persistent T;
                persistent n;
                T_local = zeros(nS,1);
                n_local = zeros(nS,1);
                for s=1:nS
                    T_local(s)=interpn(xyz.x,xyz.y,xyz.z,temp_eV(:,:,:,s),part.x,part.y,part.z);
                    n_local(s)=interpn(xyz.x,xyz.y,xyz.z,density(:,:,:,s),part.x,part.y,part.z);
                end
                
                if any([isnan(T_local) isnan(n_local)]) == 0
                    T=T_local;
                    n=n_local;
                else
                    T_local = T;
                    n_local = n;
                end
            end
    end
end

