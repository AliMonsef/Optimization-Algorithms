clc;
clear all;
close all;
%%
%Problem Parameters
cost=@(x) MOP2(x);

nvar=3;

varsize=[1 nvar];

varmin=-4;
varmax= 4;

nobj=numel(unifrnd(varmin,varmax,varsize));

%%
%NSGA-II parameters

maxit=100;
npop=100;

pc=0.7;
nc=2*round(pc*npop/2);

pm=0.4;
nm=round(pm*npop);

sigma=0.1*(varmax-varmin);
beta=0;
mu=0.02;
%%
%NSGA-II Setup

chorom.position=[];
chorom.cost=[];
chorom.rank=[];
chorom.DominationSet=[];
chorom.DominatedCount=[];
chorom.CrowdingDistance=[];

c=repmat(chorom,npop,1);

for i=1:npop
    
    c(i).position=unifrnd(varmin,varmax,varsize);
    c(i).cost=cost(c(i).position);
    
end
 
%Non-Dominated Sorting
[c,F]=NonDominatedSorting(c);

%Calculate Crowding Distance
c=CalcCrowdignDistance(c,F);

%Sort Population
[c,F]=SortPopulation(c);

%%
%NSGA-II Main Loop

for it=1:maxit
    
   
    
    %Crossover
    pc=repmat(chorom,nc/2,2);
    for j=1:nc/2
       i1=randi([1 npop]); 
       p1=c(i1);
       
       i2=randi([1 npop]); 
       p2=c(i2);
       
       [pc(j,1).position,pc(j,2).position]=Crossover(p1.position,p2.position);
       
       pc(j,1).cost=cost(pc(j,1).position);
       pc(j,2).cost=cost(pc(j,2).position);
       
    end
    pc=pc(:);
    
    %Mutation
    pm=repmat(chorom,nm,1);
    for i=1:nm
       i1=randi([1 npop]); 
       p1=c(i1);
       
       pm(i).position=Mutation(p1.position,mu,sigma);
       
       pm(i).cost=cost(pm(i).position);
       
    end
  
    %Merg
    c=[c
       pc
       pm];
    
    %First Sorting
    %Non-Dominated Sorting
    [c,F]=NonDominatedSorting(c);

    %Calculate Crowding Distance
    c=CalcCrowdignDistance(c,F);

    %Sort Population
    [c,F]=SortPopulation(c);

    %Truncate
    c=c(1:npop);

    %Second Sorting
    %Non-Dominated Sorting
    [c,F]=NonDominatedSorting(c);

    %Calculate Crowding Distance
    c=CalcCrowdignDistance(c,F);

    %Sort Population
    [c,F]=SortPopulation(c);
    
    %Store F1
    %F1=c(F{1});
    
    %Show Iteration Information
    disp(['Iteration: ' num2str(it) ' Number Of F1 Members: '...
        num2str(numel(F{1}))]);
    
    %Plot F1 Costs
    figure(1);
    PlotCost(c);
end
%%
%Results

%%
%Functions
function z=MOP2(x)
 
    n=numel(x);
    
    z1=1-exp(-sum((x-1/sqrt(n)).^2));
    z2=1-exp(-sum((x+1/sqrt(n)).^2));
    
    z=[z1,z2]';
    
end

function b=Dominate(x,y)
    
    if isstruct(x)
       x=x.cost; 
    end
    if isstruct(y)
        y=y.cost;
    end
    
    b=(all(x<=y) && any(x<y));
    
end

function [pop,F]=NonDominatedSorting(pop)
    
    npop=numel(pop);
    
    for i=1:npop
       pop(i).DominationSet=[];
       pop(i).DominatedCount=0;
    end
    F{1}=[];
    
    for i=1:npop
        for j=i+1:npop
            
            if Dominate(pop(i),pop(j))
               pop(i).DominationSet=[pop(i).DominationSet j];
               pop(j).DominatedCount=pop(j).DominatedCount+1;
            end
            if Dominate(pop(j),pop(i))
               pop(j).DominationSet=[pop(j).DominationSet i];
               pop(i).DominatedCount=pop(i).DominatedCount+1; 
            end
            
        end
        if pop(i).DominatedCount==0
            F{1}=[F{1} i];
            pop(i).rank=1;
        end
    end
   
    k=1;
    
    while true
      
        Q=[];
        
        for i=F{k}
            for j=pop(i).DominationSet
                pop(j).DominatedCount=pop(j).DominatedCount-1;
                if pop(j).DominatedCount==0
                   Q=[Q j]; 
                   pop(j).rank=k+1;
                end                
            end
        end
        
        if isempty(Q)
           break;  
        end
        
        F{k+1}=Q;
        k=k+1;
        
    end
     
end

function pop=CalcCrowdignDistance(pop,F)
    
    nf=numel(F);
    
    for k=1:nf
        
        Costs=[pop(F{k}).cost];
        
        nobj=size(Costs,1);
        
        n=numel(F{k});
        
        d=zeros(n,nobj);
        
        for j=1:nobj
            
           [cj,so]=sort(Costs(j,:));
           
           d(so(1),j)=inf;
           
           for i=2:n-1
              d(so(i),j)=abs(cj(i+1)-cj(i-1))/abs(cj(1)-cj(end)); 
           end
           
           d(so(end),j)=inf;
           
        end
        
        for i=1:n
           pop(F{k}(i)).CrowdingDistance=sum(d(i,:));
        end
           
    end
    
end

function [pop,F]=SortPopulation(pop)
    
    %Sort Based On Crowding Distance
    [~,CDso]=sort([pop.CrowdingDistance],'descend');
    pop=pop(CDso);
    
    %Sort Based On Rank
    [~,Rso]=sort([pop.rank]);
    pop=pop(Rso);
    
    %Update Fronts
    Ranks=[pop.rank];
    maxrank=max(Ranks);
    F=cell(maxrank,1);
    for r=1:maxrank
       F{r}=find(Ranks==r); 
    end
end

function [y1,y2]=Crossover(c1,c2)
    
    n=numel(c1);
    
   alfa=randi([0 1],1,n);
    
   y1=alfa.*c1+(1-alfa).*c2;
   y2=(1-alfa).*c1+alfa.*c2;

end

function y=Mutation(x,mu,sigma)
    
    n=numel(x);
    
    SelectedN=ceil(n*mu);
    
    List=randsample(n,SelectedN);
    
    y=x;
    
    y(List)=y(List)+sigma*randn(size(List));
   
end

function PlotCost(pop)
    
    Costs=[pop.cost];
    
    plot(Costs(1,:),Costs(2,:),'ro','MarkerSize',12);
    xlabel('1st Objective');
    ylabel('2nd Objective');
    grid on;
end

