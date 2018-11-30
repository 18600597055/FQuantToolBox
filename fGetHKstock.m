classdef fGetHKstock < handle
    %% fGetHKstock
    % by LiYang_faruto
    % Email:farutoliyang@foxmail.com
    % 2015/6/1
    %% properties
    properties
        
        Code = '00700';
        
        StartDate = 'All';
        EndDate = datestr(today,'yyyymmdd');
        
        isSave = 0;
        isPlot = 0;
        
    end
    %% properties(SetAccess = private, GetAccess = public)
    properties(SetAccess = private, GetAccess = public)
        
        
    end
    
    %% properties(Access = protected)
    properties(Access = protected)
        
    end
    
    %% properties(Access = private)
    properties(Access = private)
        
    end
    
    %% methods
    
    methods
        %% fGetHKstock()
        function obj = fGetHKstock( varargin )
            
        end
        
        %% GetList()
        function OutputData = GetList(obj)
            OutputData = [];
            % %===���������� ��ʼ===
            Flag = ParaCheck(obj);
            if 0 == Flag
                str = ['������������Ƿ���ȷ��'];
                disp(str)
                return;
            end
            
            % %===���������� ���===
            
            URL = 'http://quote.eastmoney.com/hk/HStock_list.html';
            URLchar = urlread(URL,'Charset','gb2312');
            
            URLString = java.lang.String(URLchar);
            
            expr = ['<li><a href="http://quote.eastmoney.com/hk/','.*?',...
                'target="_blank">(','(.*?)','</a></li>'];
            
            tData = regexpi(URLchar, expr,'tokens');
            Len = length(tData);
            OutputData = cell(Len,2);
            for i = 1:Len
                tD = tData{1,i};
                while iscell(tD)
                    tD = tD{1,1};
                end
                
                ind = find( tD == ')' );
                tCode = tD(1:ind-1);
                tName = tD(ind+1:end);
                OutputData(i,:) = [{tCode},{tName}];
            end
            
            % % % Save
            if 1 == obj.isSave && ~isempty(OutputData)
                tOutputData = OutputData;
                for i = 1:Len
                    
                    tCode = OutputData{i,1};
                    tCode = ['''',tCode];
                    tOutputData{i,1} = tCode;
                end
                
                FolderStr = ['./DataBaseTemp/HKstock'];
                if ~isdir( FolderStr )
                    mkdir( FolderStr );
                end
                
                FileName = ['HKstockList',];
                FileString = [FolderStr,'/',FileName,'.xlsx'];
                FileExist = 0;
                if exist(FileString, 'file') == 2
                    FileExist = 1;
                end
                if 1 == FileExist
                    FileString = [FolderStr,'/',FileName,'(1)','.xlsx'];
                end
                
                Headers = {'����','����'};
                FileName = FileString;
                ColNamesCell = Headers;
                Data = tOutputData;
                [Status, Message] = SaveData2File(Data, FileName, ColNamesCell);
                
                str = ['HKstockList�����ѱ�����',FileString];
                disp(str);
            end
            
        end
        
        %% GetPrice()
        function [OutputData,Headers] = GetPrice(obj)
            % % ���˵������е���ͼ�Ϊ0 ��Ҫע�⣡
            OutputData = [];
            Headers = {'����','��','��','��','��','��','��','�ǵ���','�ǵ���','���'};
            % %===���������� ��ʼ===
            Flag = ParaCheck(obj);
            if 0 == Flag
                str = ['������������Ƿ���ȷ��'];
                disp(str)
                return;
            end
            
            % %===���������� ���===
            tSymbol = obj.Code;
            
            URL_Pattern = ['http://stock.finance.sina.com.cn/hkstock/api/jsonp.php/' ...
                'Var=/HistoryTradeService.getHistoryRange?symbol=%s'];
            
            tURL = sprintf(URL_Pattern, tSymbol);
            Content = urlread(tURL);
            
            ind = find(Content == '"');
            Temp = Content(ind(1)+1:ind(2)-1);
            YearMax = str2double(Temp(1:4));
            SeasonMax = str2double(Temp(6:end));
            Temp = Content(ind(3)+1:ind(4)-1);
            YearMin = str2double(Temp(1:4));
            SeasonMin = str2double(Temp(6:end));            
            
            if strcmpi(obj.StartDate, 'all') || strcmpi(obj.EndDate, 'all')
                
                sYear = YearMin;
                eYear = YearMax;
                
                sJiDu = SeasonMin;
                eJiDu = SeasonMax;
            else
                sYear = str2double(obj.StartDate(1:4));
                eYear = str2double(obj.EndDate(1:4));
                sM = str2double(obj.StartDate(5:6));
                eM = str2double(obj.EndDate(5:6));
                
                for i = 1:4
                    if sM>=3*i-2 && sM<=3*i
                        sJiDu = i;
                    end
                    if eM>=3*i-2 && eM<=3*i
                        eJiDu = i;
                    end
                end
                
            end
            
            Len = (eYear-sYear)*240+250;
            DTemp = cell(Len,10);
            rLen = 1;
            for i = sYear:eYear
                for j = 1:4
                    if i == sYear && j < sJiDu
                        continue;
                    end
                    if i == eYear && j > eJiDu
                        continue;
                    end
                    
                    URL = 'http://stock.finance.sina.com.cn/hkstock/history/00700.html';
                    tPost = {'year',num2str(i),'season',num2str(j)};

                    [~,TableCell] = GetTableFromWeb(URL,'gb2312','Post',tPost);
                    
                    if iscell( TableCell ) && ~isempty(TableCell)
                        TableInd = 1;
                        FIndCell = TableCell{TableInd};
                    else
                        FIndCell = [];
                    end
                    
                    % ���� �� �� �� �� �� �� ��Ȩ����
                    FIndCell = FIndCell(3:end,:);
                    FIndCell = FIndCell(end:(-1):1,:);
                    
                    if ~isempty(FIndCell)
                        LenTemp = size(FIndCell,1);
                        
                        DTemp(rLen:(rLen+LenTemp-1),:) = FIndCell;
                        rLen = rLen+LenTemp;
                    end
                end
            end
            DTemp(rLen:end,:) = [];
            % �����¹ɸ����л������ԭ��DTempΪ��
            if isempty(DTemp)
                return;
            end
            
            % {'����','���̼�','�ǵ���','�ǵ���','�ɽ���','�ɽ���','���̼�','��߼�','��ͼ�','���'}
            % ������
            % {'����','��','��','��','��','��','��','�ǵ���','�ǵ���','���'};
            Dates = DTemp(:,1);
            Close = DTemp(:,2);
            ChgA = DTemp(:,3);
            ChgP = DTemp(:,4);
            Vol = DTemp(:,5);
            Amt = DTemp(:,6);
            Open = DTemp(:,7);
            High = DTemp(:,8);
            Low = DTemp(:,9);
            Swing = DTemp(:,10);
            
            DTemp = [ Dates,Open,High,Low,Close,Vol,Amt,ChgA,ChgP,Swing ];
            DTemp = cellfun(@str2double,DTemp);   
            
            % BeginDate,EndDate
            sDate = str2double(obj.StartDate);
            eDate = str2double(obj.EndDate);
            
%             [~,sInd] = min( abs(DTemp(:,1)-sDate) );
%             [~,eInd] = min( abs(DTemp(:,1)-eDate) );
            sInd = find(DTemp(:,1)>=sDate,1,'first');
            eInd = find(DTemp(:,1)<=eDate,1,'last');
            
            OutputData = DTemp(sInd:eInd,:);
            
            % % %���ݴ�����Ϊ0�������滻ΪNaN
            OutputData(OutputData==0) = NaN;
            
            % % % Save
            if 1 == obj.isSave && ~isempty(OutputData)
                tOutputData = OutputData;
                
                FolderStr = ['./DataBaseTemp/HKstock'];
                if ~isdir( FolderStr )
                    mkdir( FolderStr );
                end
                
                if strcmpi(obj.StartDate, 'all') || strcmpi(obj.EndDate, 'all')
                    FileName = [obj.Code,'.HK_All'];
                else
                    tdatefrom = obj.StartDate;
                    tdateto = obj.EndDate;
                    FileName = [obj.Code,'.HK_',tdatefrom,'-',tdateto];
                end
                FileString = [FolderStr,'/',FileName,'.xlsx'];
                FileExist = 0;
                if exist(FileString, 'file') == 2
                    FileExist = 1;
                end
                if 1 == FileExist
                    FileString = [FolderStr,'/',FileName,'(1)','.xlsx'];
                end

                FileName = FileString;
                ColNamesCell = Headers;
                Data = tOutputData;
                [Status, Message] = SaveData2File(Data, FileName, ColNamesCell);
                
                str = [obj.Code,'.HK�����ѱ�����',FileString];
                disp(str);
            end
            
            % % % Plot
            if 1 == obj.isPlot && ~isempty(OutputData)
                % % ���˵������е���ͼ�Ϊ0 ��Ҫע�⣡
                % % �������ݼ�飬Ϊ0��������Щ����
                
                
                scrsz = get(0,'ScreenSize');
                figure('Position',[scrsz(3)*1/4 scrsz(4)*1/6 scrsz(3)*4/5 scrsz(4)]*3/4);
                
                subplot(3,1,1:2);
                
                OHLC = OutputData(:,2:5);
                KplotNew(OHLC);
                % ����ʱ�����趨
                Dates = OutputData(:,1);
                Style = 0;
                XTRot = [];
                LabelSet(gca, Dates, [], [], Style,XTRot);
                str = [obj.Code,'.HK  K��ͼ'];
                title(str,'FontWeight','Bold');
                
                subplot(3,1,3);
                Vol = OutputData(:,6);
                bar(Vol);
                str = ['�ɽ���'];
                ylabel(str,'FontWeight','Bold');
                Dates = OutputData(:,1);
                Style = 0;
                XTRot = [];
                LabelSet(gca, Dates, [], [], Style,XTRot);
                xlim([0,1+length(Dates)]);
            end
            
        end
        
        %% GetProfile()
        function [OutputData] = GetProfile(obj)
            OutputData = [];
            
                        
            URL_Pattern = ['http://stock.finance.sina.com.cn/hkstock/info/%s.html'];
            tSymbol = obj.Code;
            tURL = sprintf(URL_Pattern, tSymbol);
%             Content = urlread(tURL);     
            
            [TableTotalNum,TableCell] = GetTableFromWeb(tURL,'gbk');
            
            if TableTotalNum>=1
                OutputData = TableCell{1,1};
            else
                disp('��ȡ����ʧ�ܣ��������������');
                return;
            end
            
            % % % Save
            if 1 == obj.isSave && ~isempty(OutputData)
                tOutputData = OutputData;
                
                FolderStr = ['./DataBaseTemp/HKstock'];
                if ~isdir( FolderStr )
                    mkdir( FolderStr );
                end
                
                FileName = [obj.Code,'.HK_Profile'];

                FileString = [FolderStr,'/',FileName,'.xlsx'];
                FileExist = 0;
                if exist(FileString, 'file') == 2
                    FileExist = 1;
                end
                if 1 == FileExist
                    FileString = [FolderStr,'/',FileName,'(1)','.xlsx'];
                end

                FileName = FileString;
                ColNamesCell = [];
                Data = tOutputData;
                [Status, Message] = SaveData2File(Data, FileName, ColNamesCell);
                
                str = [obj.Code,'.HK��˾���������ѱ�����',FileString];
                disp(str);
            end            
            
        end   
        
        %% GetDividends()
        function [OutputData] = GetDividends(obj)
            OutputData = [];
            
                        
            URL_Pattern = ['http://stock.finance.sina.com.cn/hkstock/dividends/%s.html'];
            tSymbol = obj.Code;
            tURL = sprintf(URL_Pattern, tSymbol);
%             Content = urlread(tURL);     
            
            [TableTotalNum,TableCell] = GetTableFromWeb(tURL,'gbk');
            
            if TableTotalNum>=1
                OutputData = TableCell{1,1};
            else
                disp('��ȡ����ʧ�ܣ��������������');
                return;
            end
            
            % % % Save
            if 1 == obj.isSave && ~isempty(OutputData)
                tOutputData = OutputData;
                
                FolderStr = ['./DataBaseTemp/HKstock'];
                if ~isdir( FolderStr )
                    mkdir( FolderStr );
                end
                
                FileName = [obj.Code,'.HK_Dividends'];

                FileString = [FolderStr,'/',FileName,'.xlsx'];
                FileExist = 0;
                if exist(FileString, 'file') == 2
                    FileExist = 1;
                end
                if 1 == FileExist
                    FileString = [FolderStr,'/',FileName,'(1)','.xlsx'];
                end

                FileName = FileString;
                ColNamesCell = [];
                Data = tOutputData;
                [Status, Message] = SaveData2File(Data, FileName, ColNamesCell);
                
                str = [obj.Code,'.HK�ֺ���Ϣ�����ѱ�����',FileString];
                disp(str);
            end               
            
        end         
        
        %% ���������麯��
        function Flag = ParaCheck(obj, varargin )
            Flag = 1;
            
            % %===���������� ��ʼ===
            
            %             checkflag = ismember( lower(obj.DownUpSampling),lower(obj.DownUpSampling_ParaList) );
            %             if checkflag ~= 1
            %                 str = ['DownUpSampling��������������飡��ѡ�Ĳ����б�Ϊ����Сд���У���'];
            %                 disp(str);
            %                 ParaList = obj.DownUpSampling_ParaList
            %                 Flag = 0;
            %                 return;
            %             end
            
            % %===���������� ���===
        end
        
        
        
        
        
    end
    
end
