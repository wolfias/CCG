function uv = annulus_riemann_map(mesh)
% compute riemann map from annulus surface to canonical annulus in unit
% disk, assume the longest boundary to be outer boundary
face = mesh.face;
edge = mesh.edge;
eif = mesh.eif;
halfedge = mesh.halfedge;
heif = mesh.heif;
nf = mesh.nf;
ne = mesh.ne;
nv = mesh.nv;
% compute harmonic function f with fixed value on two boundaries of annulus
% f(b1) = 0, f(b2) = 1
bds = boundary(face);
b1 = bds{1};
b2 = bds{2};
if length(b1)<length(b2)
    b1 = bds{2};
    b2 = bds{1};
end
f = nan(mesh.nv,1);
f(b1) = 1;
f(b2) = 0;
f = harmonic_function(mesh, f);
E = harmonic_energy(mesh, f);
df = exterior_derivative(mesh,f,0);
% find a shortest path between two boundaries b1,b2
cc = shortest_path(mesh,[b1(1),b2(1)]);
% label face
% indf == 1 indicate faces on one side of path
% indf == -1 indicate faces on the other side
indf = zeros(nf,1);
hes = sparse(halfedge(:,1),halfedge(:,2),heif,nv,nv);
f1 = hes(cc(1:end-1)+(cc(2:end)-1)*nv);
f2 = hes(cc(2:end)+(cc(1:end-1)-1)*nv);
indf(f1) = 1;
indf(f2) = -1;
indf2 = zeros(ne,1);
ind1 = eif(:,1)>0;
indf2(ind1) = indf(eif(ind1,1));
ind2 = eif(:,2)>0;
indf2(ind2) = indf2(ind2) + indf(eif(ind2,2));
indf(eif(indf2==1&ind1,1)) = 1;
indf(eif(indf2==1&ind2,2)) = 1;
indf(eif(indf2==-1&ind1,1)) = -1;
indf(eif(indf2==-1&ind2,2)) = -1;
% define g on open surface, dg 
g = rand(nv,1);
g(cc) = 0;
w = exterior_derivative(mesh,g,0);
% g == 1 on the other side, adjust w
g(cc) = 1;
inde = zeros(ne,1);
inde(ind1) = inde(ind1) + indf(eif(ind1,1));
inde(ind2) = inde(ind2) + indf(eif(ind2,2));
inde = inde>0;
w(inde) = g(edge(inde,2))-g(edge(inde,1));
% delta(w)
delta_w = exterior_co_derivative(mesh,w,1);
L = laplace_beltrami(mesh);
L(1,1) = L(1,1)-1;
h = -L\delta_w;
dh = exterior_derivative(mesh,h,0);
% dh is closed harmonic one form
dh = w + dh/2;
% integrate df + 1i*dh
des = sparse(edge(:,1),edge(:,2),dh,nv,nv);
des = des - conj(des');
k = sum(full(des(b1+(b1([2:end,1])-1)*nv)));
dh = dh/k;
deta = df + 1i*dh;
% eta has period 1
eta = integration(mesh,deta);
% exponential map
z = exp(2*pi*eta);
uv = [real(z),imag(z)];
